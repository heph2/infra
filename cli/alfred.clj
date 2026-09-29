(ns alfred
  (:require [cheshire.core :as json]
            [clojure.edn :as edn]
            [clojure.java.io :as io]
            [clojure.java.shell :as shell]
            [clojure.string :as str]))

(def default-data-file "data/network.edn")

(defn fail! [message]
  (throw (ex-info message {})))

(defn parse-csv [text]
  (let [quote (char 34)]
    (loop [chars (seq text), field (StringBuilder.), row [], rows []]
      (if-let [ch (first chars)]
        (cond
          (= ch quote)
          (let [[rest-chars value]
                (loop [remaining (next chars), value (StringBuilder.)]
                  (if-let [current (first remaining)]
                    (if (= current quote)
                      (if (= (second remaining) quote)
                        (recur (nnext remaining) (doto value (.append quote)))
                        [(next remaining) (str value)])
                      (recur (next remaining) (doto value (.append current))))
                    (fail! "unterminated CSV quote")))]
            (recur rest-chars (StringBuilder. value) row rows))
          (= ch \,)
          (recur (next chars) (StringBuilder.) (conj row (str field)) rows)
          (= ch \newline)
          (recur (next chars) (StringBuilder.) [] (conj rows (conj row (str field))))
          (= ch \return)
          (recur (next chars) field row rows)
          :else
          (recur (next chars) (doto field (.append ch)) row rows))
        (let [row (conj row (str field))]
          (if (and (= 1 (count row)) (str/blank? (first row))) rows (conj rows row)))))))

(defn parse-amount [value]
  (let [value (-> value str/trim (str/replace #"[^0-9.\-]" ""))]
    (if (str/blank? value) 0.0 (Double/parseDouble value))))

(defn limit-series [series months]
  (if months
    (take-last (Integer/parseInt (str months)) series)
    series))

(defn expense-series [csv]
  (let [rows (parse-csv csv)
        header (first (filter #(= "account" (str/lower-case (str/trim (first %)))) rows))
        total (last (filter #(= "total:" (str/lower-case (str/trim (first %)))) rows))]
    (when-not (and header total)
      (fail! "hledger output did not contain an account header and Total row"))
    (mapv (fn [period amount] {:period period :amount (parse-amount amount)})
          (rest header) (rest total))))

(defn ipv4-bytes [address]
  (let [parts (str/split address #"\." -1)]
    (when-not (= 4 (count parts))
      (fail! (str "invalid IPv4 address: " address)))
    (mapv (fn [part]
            (let [value (Integer/parseInt part)]
              (when (or (neg? value) (> value 255))
                (fail! (str "invalid IPv4 address: " address)))
              value)) parts)))

(defn ipv6-groups [address]
  (let [parts (str/split address #"::" -1)]
    (when (> (count parts) 2)
      (fail! (str "invalid IPv6 address: " address)))
    (letfn [(groups [part]
              (if (str/blank? part)
                []
                (mapcat (fn [group]
                          (if (str/includes? group ".")
                            (let [[a b c d] (ipv4-bytes group)]
                              [(+ (* a 256) b) (+ (* c 256) d)])
                            (let [value (Integer/parseInt group 16)]
                              (when (> value 65535)
                                (fail! (str "invalid IPv6 address: " address)))
                              [value])))
                        (str/split part #":"))))]
      (let [left (groups (first parts))
            right (groups (if (= 2 (count parts)) (second parts) ""))
            groups (if (= 2 (count parts))
                     (concat left (repeat (- 8 (count left) (count right)) 0) right)
                     (concat left right))]
        (when-not (= 8 (count groups))
          (fail! (str "invalid IPv6 address: " address)))
        (vec (mapcat (fn [group] [(quot group 256) (mod group 256)]) groups))))))

(defn ip-bytes [address]
  (cond
    (re-matches #"[0-9]+(\.[0-9]+){3}" address) (ipv4-bytes address)
    (str/includes? address ":") (ipv6-groups address)
    :else (fail! (str "invalid IP address: " address))))

(defn parse-cidr [cidr]
  (let [[address prefix] (str/split cidr #"/" 2)
        bytes (ip-bytes address)
        prefix (Integer/parseInt prefix)
        bits (* 8 (count bytes))]
    (when (or (neg? prefix) (> prefix bits))
      (fail! (str "invalid CIDR prefix: " cidr)))
    {:cidr cidr :bytes bytes :prefix prefix :bits bits}))

(defn same-network? [address network]
  (let [address (ip-bytes address)
        network-bytes (:bytes network)
        prefix (:prefix network)]
    (and (= (count address) (count network-bytes))
         (every? true?
                 (for [index (range (count address))
                       :let [remaining (- prefix (* 8 index))
                             mask (if (>= remaining 8)
                                    0xff
                                    (bit-and 0xff (bit-shift-left 0xff (- 8 remaining))))]
                       :when (pos? remaining)]
                   (= (bit-and (nth address index) mask)
                      (bit-and (nth network-bytes index) mask)))))))

(defn network-records [data]
  (map #(assoc % :parsed (parse-cidr (:cidr %))) (:networks data)))

(defn address-records [data]
  (mapcat (fn [host]
            (map (fn [address] {:host (:id host) :address address})
                 (or (:addresses host) (when-let [address (:address host)] [address]))))
          (:hosts data)))

(defn validate-network-data [data]
  (let [networks (network-records data)
        records (address-records data)
        with-normalized (map (fn [record]
                               (try
                                 (assoc record :normalized (vec (ip-bytes (:address record))))
                                 (catch Exception _
                                   (assoc record :invalid true)))) records)
        invalid (for [{:keys [host address invalid]} with-normalized :when invalid]
                  {:type :invalid-address :host host :address address})
        valid (remove :invalid with-normalized)
        duplicates (for [[normalized records] (group-by :normalized valid)
                         :when (> (count records) 1)]
                     {:type :duplicate-address
                      :address (:address (first records))
                      :hosts (mapv :host records)})
        outside (for [{:keys [host address]} valid
                      :when (not-any? #(same-network? address (:parsed %)) networks)]
                  {:type :address-outside-network :host host :address address})]
    (vec (concat invalid duplicates outside))))

(defn parse-json-array [text]
  (let [value (json/parse-string text)]
    (if (sequential? value) (vec value) (fail! "expected a JSON array"))))

(defn due-tasks [tasks today]
  (->> tasks
       (filter #(not (true? (:done %))))
       (filter #(when-let [due (:due_date %)]
                  (try (not (pos? (.compareTo (java.time.LocalDate/parse (subs due 0 10)) today)))
                       (catch Exception _ false))))
       (sort-by #(or (:due_date %) ""))))

(defn command-result [args options]
  (apply shell/sh (concat args (when-let [dir (:dir options)] [:dir dir]))))

(defn run-command!
  ([args] (run-command! args {}))
  ([args options]
   (let [{:keys [exit out err]} (command-result args options)]
     (when-not (zero? exit)
       (fail! (str (str/join " " args) " failed (" exit "): " (str/trim err))))
     out)))

(defn flake-path [options]
  (let [path (or (:flake options) (System/getenv "ALFRED_FLAKE") ".")]
    (when-not (.isFile (io/file path "flake.nix"))
      (fail! (str "Nix commands require a flake directory; pass --flake PATH (not found: " path ")")))
    path))

(defn read-data [path]
  (try
    (edn/read-string (slurp path))
    (catch java.io.FileNotFoundException _
      (fail! (str "network data file not found: " path)))
    (catch Exception error
      (fail! (str "invalid network data: " (.getMessage error))))))

(defn print-network [data network-filter]
  (doseq [host (:hosts data)
          address (or (:addresses host) [(:address host)])
          :when (or (nil? network-filter)
                    (some #(and (= network-filter (:id %))
                                (same-network? address (parse-cidr (:cidr %)))) (:networks data)))]
    (println (format "%-18s %-18s %s" address (:id host) (or (:role host) "")))))

(defn print-expenses [series]
  (let [maximum (max 1.0 (apply max (map :amount series)))]
    (doseq [{:keys [period amount]} series]
      (println (format "%-10s %-30s %10.2f" period
                       (apply str (repeat (int (* 30 (/ amount maximum))) "█")) amount)))))

(def boolean-options #{:expenses :help})

(defn parse-args [args]
  (loop [remaining (seq args), positionals [], options {}]
    (if-not (seq remaining)
      {:positionals positionals :options options}
      (let [arg (first remaining)]
        (if-not (str/starts-with? arg "--")
          (recur (next remaining) (conj positionals arg) options)
          (let [[key inline-value] (str/split (subs arg 2) #"=" 2)
                option-key (keyword key)]
            (if (contains? boolean-options option-key)
              (recur (next remaining) positionals (assoc options option-key true))
              (if inline-value
              (recur (next remaining) positionals (assoc options (keyword key) inline-value))
                (if (second remaining)
                  (recur (nnext remaining) positionals
                         (assoc options option-key (second remaining)))
                  (fail! (str "missing value for --" key)))))))))))

(defn data-path [{:keys [data]}]
  (or data (System/getenv "ALFRED_DATA_FILE") default-data-file))

(defn expand-home [path]
  (if (str/starts-with? path "~/" )
    (str (System/getProperty "user.home") (subs path 1))
    path))

(defn money-command [subcommand options]
  (let [file (some-> (or (:file options) (System/getenv "LEDGER_FILE")) expand-home)]
    (when-not file (fail! "set LEDGER_FILE or pass --file JOURNAL"))
    (let [account (or (:account options) "expenses")
          csv (run-command! ["hledger" "-f" file "bal" "-M" account "-O" "csv"])
          series (limit-series (expense-series csv) (:months options))]
      (case subcommand
        "chart" (print-expenses series)
        "summary" (let [{:keys [amount]} (last series)]
                    (println (format "Latest period: %.2f" (double (or amount 0)))))
        (fail! "usage: alfred money chart|summary [--file JOURNAL]")))))

(defn tasks-command [subcommand options]
  (let [tasks (json/parse-string (run-command! ["vja" "ls" "--json"]) true)
        today (java.time.LocalDate/now)
        selected (if (= subcommand "upcoming")
                   (filter #(not (true? (:done %))) tasks)
                   (due-tasks tasks today))]
    (doseq [task (sort-by #(or (:due_date %) "") selected)]
      (println (format "%-12s %s" (or (some-> (:due_date task) (subs 0 10)) "no due date") (:title task))))
    (when (:expenses options)
      (let [file (some-> (or (:file options) (System/getenv "LEDGER_FILE")) expand-home)]
        (when-not file (fail! "--expenses requires LEDGER_FILE or --file JOURNAL"))
        (let [series (expense-series (run-command! ["hledger" "-f" file "bal" "expenses" "-p" "thismonth" "-O" "csv"]))]
          (println (format "Expenses this month: %.2f" (double (or (:amount (last series)) 0)))))))))

(defn nix-targets [flake]
  (let [nixos (parse-json-array (run-command! ["nix" "eval" (str flake "#nixosConfigurations") "--apply" "builtins.attrNames" "--json"] {:dir flake}))
        darwin (parse-json-array (run-command! ["nix" "eval" (str flake "#darwinConfigurations") "--apply" "builtins.attrNames" "--json"] {:dir flake}))]
    (concat (map #(hash-map :kind :nixos :name % :recipe ["build" %]) nixos)
            (map #(hash-map :kind :darwin :name % :recipe ["build-darwin" %]) darwin))))

(defn target-for [targets name]
  (or (first (filter #(= name (:name %)) targets))
      (fail! (str "unknown Nix target: " name))))

(defn nix-command [subcommand host options]
  (let [flake (flake-path options)
        targets (nix-targets flake)]
    (case subcommand
      "hosts" (doseq [{:keys [kind name]} targets] (println (format "%-8s %s" (clojure.core/name kind) name)))
      (let [{:keys [recipe kind name]} (target-for targets host)
            command (str "just " (str/join " " recipe))]
        (case subcommand
          "plan" (println (format "Target: %s (%s)\nBuild:  %s" name (clojure.core/name kind) command))
          "build" (do (println (str "Running: " command)) (run-command! (into ["just"] recipe) {:dir flake}))
          (fail! "usage: alfred nix hosts|plan HOST|build HOST"))))))

(defn usage []
  (println (str/join "\n" [
                         "alfred — personal operations CLI"
                         ""
                         "  alfred today [--expenses] [--file JOURNAL]"
                         "  alfred tasks upcoming"
                         "  alfred money chart|summary [--file JOURNAL] [--months N]"
                         "  alfred ip list|check [--network ID] [--data FILE]"
                         "  alfred host list|show HOST [--data FILE]"
                         "  alfred nix hosts|plan HOST|build HOST [--flake PATH]"
                         ""
                         "Read-only except nix build; deployments and task edits remain separate." ])))

(defn run [args]
  (try
    (let [{:keys [positionals options]} (parse-args args)
          [command subcommand argument] positionals]
      (let [result (cond
        (or (= command "help") (nil? command) (:help options)) (usage)
        (= command "today") (tasks-command "today" options)
        (= command "tasks") (tasks-command subcommand options)
        (= command "money") (money-command subcommand options)
        (= command "ip") (let [data (read-data (data-path options))]
                            (case subcommand
                              "list" (print-network data (:network options))
                              "check" (let [errors (validate-network-data data)]
                                        (if (seq errors)
                                          (do (doseq [error errors] (println (pr-str error))) 1)
                                          (println "IP inventory OK")))
                              (fail! "usage: alfred ip list|check")))
        (= command "host") (let [data (read-data (data-path options))]
                              (case subcommand
                                "list" (doseq [host (:hosts data)] (println (format "%-18s %s" (:id host) (or (:role host) ""))))
                                "show" (if-let [host (some #(when (= argument (:id %)) %) (:hosts data))]
                                         (println (pr-str host))
                                         (fail! (str "unknown host: " argument)))
                                (fail! "usage: alfred host list|show HOST")))
        (= command "nix") (nix-command subcommand argument options)
        :else (fail! (str "unknown command: " command)))]
        (if (integer? result) result 0)))
    (catch Exception error
      (binding [*out* *err*] (println (str "alfred: " (.getMessage error))))
      1)))

(defn -main [& args]
  (System/exit (run args)))

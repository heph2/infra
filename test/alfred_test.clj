(ns alfred-test
  (:require [clojure.test :refer [deftest is testing run-tests]]))

(load-file "cli/alfred.clj")

(deftest network-validation-catches-conflicts
  (testing "duplicate and out-of-network addresses"
    (let [data {:networks [{:id "lan" :cidr "192.168.1.0/24"}]
                :hosts [{:id "zima" :addresses ["192.168.1.30"]}
                        {:id "duplicate" :addresses ["192.168.1.30"]}
                        {:id "outside" :addresses ["10.0.0.4"]}]}
          errors (alfred/validate-network-data data)]
      (is (= 2 (count errors)))
      (is (some #(= :duplicate-address (:type %)) errors))
      (is (some #(= :address-outside-network (:type %)) errors)))))

(deftest expense-series-uses-total-row
  (let [csv "\"account\",\"2026-01\",\"2026-02\"\n\"expenses:food\",\"€10\",\"0\"\n\"Total:\",\"€10\",\"€100\"\n"]
    (is (= [{:period "2026-01" :amount 10.0}
            {:period "2026-02" :amount 100.0}]
           (alfred/expense-series csv)))))

(deftest task-filter-includes-overdue-and-today
  (let [tasks [{:id 1 :title "overdue" :due_date "2026-04-01T10:00:00Z" :done false}
               {:id 2 :title "today" :due_date "2026-04-06T10:00:00Z" :done false}
               {:id 3 :title "future" :due_date "2026-04-07T10:00:00Z" :done false}
               {:id 4 :title "done" :due_date "2026-04-01T10:00:00Z" :done true}]]
    (is (= [1 2]
           (mapv :id (alfred/due-tasks tasks (java.time.LocalDate/parse "2026-04-06")))))))

(deftest expense-series-can-be-limited
  (is (= [{:period "2026-02" :amount 100.0}]
         (alfred/limit-series [{:period "2026-01" :amount 10.0}
                               {:period "2026-02" :amount 100.0}] 1))))

(deftest ipv6-network-membership-is-checked
  (is (alfred/same-network? "2a07:7e81:85f5::cafe"
                            (alfred/parse-cidr "2a07:7e81:85f5::/64")))
  (is (not (alfred/same-network? "2a01:4f9:c012:4045::1"
                                 (alfred/parse-cidr "2a07:7e81:85f5::/64")))))

(deftest malformed-ipv6-is-reported
  (is (= :invalid-address
         (:type (first (alfred/validate-network-data
                        {:networks [{:id "v6" :cidr "2001:db8::/64"}]
                         :hosts [{:id "bad" :addresses ["10000::1"]}]}))))))

(deftest invalid-ip-check-returns-failure
  (let [file (java.io.File/createTempFile "alfred-network" ".edn")]
    (try
      (spit file (pr-str {:networks [{:id "lan" :cidr "192.168.1.0/24"}]
                           :hosts [{:id "bad" :addresses ["10.0.0.1"]}]}))
      (is (= 1 (binding [*out* (java.io.StringWriter.)]
                   (alfred/run ["ip" "check" "--data" (.getPath file)]))))
      (finally (.delete file)))))

(deftest flake-path-can-be-explicit
  (is (= "." (alfred/flake-path {:flake "."}))))

(deftest nix-json-array-is-discovered
  (is (= ["aron" "freya" "zima"]
         (alfred/parse-json-array "[\"aron\",\"freya\",\"zima\"]"))))

(defn -main []
  (let [{:keys [fail error]} (run-tests 'alfred-test)]
    (System/exit (if (zero? (+ fail error)) 0 1))))

(-main)

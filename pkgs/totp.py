import base64
import hashlib
import hmac
import struct
import time


def generate_totp(secret):
    tm = int(time.time() / 30)
    key = base64.b32decode(secret)
    b = struct.pack(">q", tm)
    hm = hmac.HMAC(key, b, hashlib.sha1).digest()
    offset = hm[-1] & 0x0F
    truncated_hash = hm[offset:offset + 4]
    code = struct.unpack(">L", truncated_hash)[0]
    code &= 0x7FFFFFFF
    return code % 1000000


secret = input().strip()
totp_code = generate_totp(secret)
print(f"{totp_code:06d}")

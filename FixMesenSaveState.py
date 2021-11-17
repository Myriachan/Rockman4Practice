import sys
import hashlib

def main(argv):
    if len(argv) < 3:
        print("python FixMesenSaveState.py Rockman4Practice.nes Rockman4Practice_3.mst")
        return 1
    
    with open(argv[1], "rb") as rm4_file:
        rm4_data = rm4_file.read()
    
    hasher = hashlib.sha1()
    hasher.update(rm4_data)
    hash = hasher.hexdigest().upper().encode("ascii")
    
    for filename in argv[2:]:
        with open(filename, "r+b") as mst_file:
            header = mst_file.read(0x36)
            if header[0x00:0x03] != b"MST":
                print("Not an MST file")
            if header[0x0E:0x36].strip(b"0123456789ABCDEF") != b"":
                print("Not an MST file")
            mst_file.seek(0x0E)
            mst_file.write(hash)

if __name__ == "__main__":
    sys.exit(main(sys.argv))

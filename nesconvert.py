import sys
import os



def main():
    dirname = os.path.dirname(__file__)
    print(f"Name of the script      : {sys.argv[0]=}")
    print(f"Arguments of the script : {sys.argv[1:]=}")

    inpringle = os.path.join(dirname, sys.argv[1])
    outpringle = os.path.join(dirname, sys.argv[2])
    with open(inpringle, "rb") as infile, open(outpringle, "w") as outfile:
        # Header
        
        # Write bytes here

        # Read Header
        print(infile.read(6))
        nes = infile.read(3)
        if (nes != b'NES'):
            print("Header is wonky")
            return
        
        infile.read(1)
        prg_size = int.from_bytes(infile.read(1)) * 16384  # In bytes
        print(prg_size)
        chr_size = int.from_bytes(infile.read(1)) * 8192  # In bytes
        print(chr_size)

        outfile.write("const int prg_rom_size = " + str(prg_size) + ";\n")
        outfile.write("const int chr_rom_size = " + str(chr_size) + ";\n")

        infile.read(10)

        outfile.write("const char prg_rom_data[" + str(prg_size) +"] = {")
        #Write Prg Rom
        for i in range(prg_size-1):
            data = infile.read(1)
            outfile.write("0x" + data.hex() + ", ")
        # Write last byte
        data = infile.read(1)
        outfile.write("0x" + data.hex())
        outfile.write("};")
        outfile.write("\n")

        outfile.write("const char chr_rom_data[" + str(chr_size) +"] = {")
        #Write Chr Rom
        for i in range(chr_size-1):
            data = infile.read(1)
            outfile.write("0x" + data.hex() + ", ")
        # Write last byte
        data = infile.read(1)
        outfile.write("0x" + data.hex())
        outfile.write("};")






if __name__ == '__main__':
    main()
#encoding:utf-8
import argparse
import os

parser = argparse.ArgumentParser(description='Trim [m:n] bytes from file')
parser.add_argument("file")
parser.add_argument("m", type=int)
parser.add_argument("n", type=int)
args = parser.parse_args()

sliced_file = bytes()
with open(args.file, "rb") as f:
    if args.m > 0:
        f.read(args.m)
    sliced_file = f.read(args.n)

save_to_file_basename = os.path.basename(args.file)
save_to_file_name = "inputs/{}.slice-{}-{}".format(save_to_file_basename, args.m, args.n)
print(save_to_file_name)
with open(save_to_file_name, "wb") as f:
    f.write(sliced_file)
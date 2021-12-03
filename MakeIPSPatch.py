import argparse
import sys
from ips_util.ips_util import Patch


def make_patch(args):
    before = None
    after = None
    with open(args.before, "rb") as f:
        before = f.read()
    with open(args.after, "rb") as f:
        after = f.read()
    
    if len(before) >= 0x1000000 or len(after) >= 0x1000000:
        raise RuntimeError("IPS format requires files <= 16 MB")
    if len(after) < len(before):
        raise RuntimeError("IPS patches cannot shrink a file.")
    
    # HACK: Support force-range by modifying "before" to always differ from "after".
    for r in args.forcerange:
        parts = r.split(",")
        if len(parts) != 2:
            raise RuntimeError("--forcerange takes start,len parameters")
        start = int(parts[0], 0)
        length = int(parts[1], 0)

        if (start < 0) or (length < 0):
            raise RuntimeError("--forcerange arguments cannot be negative")
        if start + length > len(after):
            raise RuntimeError("--forcerange arguments too large")

        if start + length > len(before):
            length = len(before) - start
        if length == 0:
            continue

        # Now the hacky part: replace "before" with NOT(after) for this range.
        replacement = bytes([x ^ 0xFF for x in after[start:start + length]])
        before = before[:start] + replacement + before[start + length:]

    patch = Patch.create(before, after)
    
    with open(args.output, "wb") as f:
        f.write(patch.encode())

    return 0


def main(argv):
    parser = argparse.ArgumentParser(
        prog = argv[0],
        description = "Makes an IPS patch file.")

    parser.add_argument("--output",
        help="Output IPS filename.",
        required=True)
    parser.add_argument("--before",
        help="Unmodified file; the original.",
        required=True)
    parser.add_argument("--after",
        help="Modified file for which to make the patch.",
        required=True)
    parser.add_argument("--forcerange",
        help="Force range start,len (with 0x for hex) to always be patched.",
        action="append")

    args = parser.parse_args(argv[1:])
    make_patch(args)


if __name__ == "__main__":
    sys.exit(main(sys.argv))

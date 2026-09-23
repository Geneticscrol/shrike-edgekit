"""Flash a bitstream with Vicharak's helper, then talk Link-6."""
try:
    import shrike
except ImportError:
    shrike = None

from main import main


def flash(path="edgekit.bin"):
    if shrike is None:
        print("shrike lib not on this UF2 - copy the bitstream with Thonny and skip this step")
        return
    shrike.flash(path)


if __name__ == "__main__":
    flash()
    main()

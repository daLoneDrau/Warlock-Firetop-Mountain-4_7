## Concrete [WalletComponent] for Warlock of Firetop Mountain.
##
## Empty subclass — `gold: int` and the rest of the base fields are used
## as-is (GDD §6: gold is "a single running numeric total, uncapped," no
## capacity/exemption logic to add). Subclassed per the project-wide
## convention (§13) that base engine classes are always subclassed rather
## than used directly, for consistency even where no behavior differs —
## the same treatment given WarlockHealthComponent.
class_name WarlockWalletComponent
extends WalletComponent


const IS_SLOT_ROOT: bool = true

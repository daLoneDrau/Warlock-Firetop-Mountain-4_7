## Concrete [HealthComponent] for Warlock of Firetop Mountain.
##
## Empty subclass — `current_hp`/`max_hp` map directly to Current/Initial
## Stamina and are used as-is (§13.1: Stamina "stays on HealthComponent,
## using its existing allow_overheal/overheal_cap fields," unmodified).
## Subclassed per the project-wide convention (§13) for consistency even
## where no behavior differs.
class_name WarlockHealthComponent
extends HealthComponent


const IS_SLOT_ROOT: bool = true

# Changelog

## 0.52

- Add `changelog.md`
- `cLib.require()`, use for avoiding circular dependencies
- `cTable.is_indexed()`: check if table keys are exclusively numerical
- Add `cPersistence`, a replacement for `cDocument` (now deprecated)
- `cReflection`: several fixes/changes:
  - `get_object_info()`: support objects without properties
  - `get_object_info()`: return table instead of string
  - `get_object_properties()`: hide implementation details
  - `is_standard_type()`: accept any value (previously passed the 'type')
  - `is_serializable_type()`: new method
  
## 0.5

- Standalone version
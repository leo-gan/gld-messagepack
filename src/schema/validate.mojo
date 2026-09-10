from runtime.value import MsgpackValue
from schema.model import SchemaDoc


comptime VK_OK = 0
comptime VK_TYPE = 1
comptime VK_REQUIRED = 2


struct ValidationResult(Copyable, ImplicitlyCopyable):
    var code: Int
    var path: String

    def __init__(out self, code: Int = 0, path: String = ""):
        self.code = code
        self.path = path


def is_valid(instance: MsgpackValue, schema: SchemaDoc) -> Bool:
    _ = instance
    _ = schema
    return True


def validate(instance: MsgpackValue, schema: SchemaDoc) -> ValidationResult:
    _ = instance
    _ = schema
    return ValidationResult()

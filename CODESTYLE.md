# Code style
It is customary to name variables and functions in camelCase style:
```D
int myVariable;
float floatVariable = 0.0f;
```

The naming of classes, enumerations, structures and template parameters should be done exclusively with a capital letter, separated also by capital letters:
```D
class SimpleClass : OtherClass;
struct SimpleStruct;
void myFunction(TemplateParametr)(TemplateParametr templateVariable) @safe;
```

This rule also applies to static variables:
```D
static immutable ubyte StaticVariable = ubyte.max;
```

Also, you need to place them in the appropriate compilation conditions so that when compiling on the windows platform, the compiler does not resent the x11 functions:
```D
version(Posix)
{
    posixFunction();
}

version(Windows)
{
    windowsFunction();
}
```

This rule also applies to the import of the corresponding modules:
```D
version(Posix)
{
    import posix.functions;
}
```

It is better to start private properties in a class with an underscore in order to add setters or getters to them if possible.

It is also advisable to use spaces instead of tabs.
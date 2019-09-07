# Intellij快捷键(MAC)
| commen | key  | Windows |
| :---   | :---: |    ---: |
Show emoji list| `comtrol(⌃) + command(⌘)+space` | NONE
←Back | `option ⌥ + command ⌘ + ←` | `Ctrl + Alt + ←` 
→Forward | `option ⌥ + command ⌘ + →` | `Ctrl + Alt + →`
basic 提示 | `control(⌃)  + space` | `Ctrl + Space` |
注释代码块 | `shift⇧ + control ⌃ + /` | `Shift + Ctrl + /` | 
expand collapse code | `command ⌘ + + -` | `Ctrl + +/-`
fast find | ` shift⇧ + shift⇧  ` | `Shift + Shift` |
Find | `command ⌘ + F` | `Shift + F` |
Fast Replace| `command ⌘ + R` | `Shift + R` |
recent file | ` command ⌘ + E ` | `Shift + E` |
UpperCase LowerCase | ` shift⇧ + command ⌘ + U ` | `Ctrl + Shift + U`
**compile** | `command ⌘ + F9` | `Ctrl + F9/B` |
**complete... 结束代码行** | `command ⌘ + shift⇧ + Entry` | `Ctrl + Shift + Enter` |
**Surround With** | `option ⌥ + command ⌘ + T` | `Ctrl + Alt + T` |
**Parameter Info** | `option ⌥ + command ⌘ + shift⇧ + T` | `Ctrl + P` |
**同时选中所有匹配 Refactor Rename** | `Ctrl+Shift+L` | `Ctrl + Alt + Shift + T` |
**小灯泡 Show Intention Actions** | `option ⌥ + ⏎` | `Alt + Enter`|
**实现类 Implementation(s)** | `option ⌥ + command ⌘ + B` | `Ctrl + Alt + B`
**Generate** | `control ⌃ + N` | `Alt + Insert` |
**Move Caret to Code Block End** || `Ctrl + ]` |
**Move Caret to Code Block Start** || `Ctrl + [`|
**Find Next / Move to Next Occurrence** |`control^ + L`||
**Find Previous / Move to Previous Occurrence** |`control^ + shift⇧ + L`||
**Select All Occurrences** |`control^ + command ⌘ + G`||
**Add Selection for Next Occurrence** |`control^ + G`||
**Unselect Occurrence** |`control⌃ + shift⇧ + G`||
**Find in Path...** |`control⌃ + shift⇧ + F`||
redo | `shift⇧ + command ⌘ + Z` | `Ctrl + Shift + Z`
undo | `command ⌘ + Z` | `Ctrl + Z`
move statement up down代码移动 | `shift⇧ + command ⌘ + ↑ or ↓` | `Ctrl + Shift + up or down`
duplicate entire lines复制代码 | `control ⌃ + command ⌘ + ↑ or ↓` | `Ctrl + D`
Move Caret Word | | `Ctrl + ←/→` |
跳转到行 | `command ⌘ + G` | `Ctrl + G` |
翻译 | `control ⌃ + command ⌘ + U` |
删除行 | `command(⌘)+ Y` | `Ctrl + Y`
main 方法 | ` psvm `
输出 | ` sout `

```python
def hello():
    return 'Hello World'
```
## lombok settings
1. Intellij Idea -> Preferences -> Compiler -> Annotation Processors

2. File -> Other Settings -> Default Settings -> Compiler -> Annotation Processors


## IDEA Plugins Recommend
- .ignore
- Alibaba Java Coding
- codehelper.generator
- FindBugs-IDEA
- Free Mybatis plugin
- GsonFormat
- Lombok Plugin
- Maven Helper
- SonarLint
- Translation
- VisualVM Launcher
- Active Tab Highlighter

激活
https://gitee.com/bluelovers/jetbrains-agent

### WIN7 ctrl + space 修改 
You need to use regedit to do this.

Step 1.
Go to start and type "regedit" in the blank space ("search" under Win 7 or "run" under Win XP)

Step 2:
Go to HKEY_CURRENT_USER/Control Panel/Input Method/Hot Keys
00000010 is for Ime/NonIme Toggle,
00000011 is for Shape Toggle
00000012 is for Punctuation 'Toggle

Step 3:
Go whichever hot key you want to modify, right click on the item and select modify,  here are the rules:
Key Modifiers: 
00 C0 00 00, no "control" or "shift" or "Alt"  (Set this value if you don't need the hot key)
01 C0 00 00, "left Alt"
02 C0 00 00, shift
04 C0 00 00, control
06 C0 00 00, control+shift
Or combination of the above to make your own.

Virtual Key:
the actual key combination, ascii code
20 00 00 00, for space
21 00 00 00, for Page_Up
00 00 00 00, for no key
ff 00 00 00, for NONE!  (Set this value if you don't need the hot key)
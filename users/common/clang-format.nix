{ config, pkgs, ... }:
{
  home.file."${config.home.homeDirectory}/.clang-format".text = ''
    AccessModifierOffset: -4
    AlignAfterOpenBracket: Align
    AlignConsecutiveAssignments: false
    AlignConsecutiveDeclarations: false
    AlignEscapedNewlines: Right
    AlignOperands: false
    AlignTrailingComments: false
    AllowAllParametersOfDeclarationOnNextLine: false
    AllowShortBlocksOnASingleLine: false
    AllowShortCaseLabelsOnASingleLine: false
    AllowShortFunctionsOnASingleLine: None
    AllowShortIfStatementsOnASingleLine: false
    AlwaysBreakAfterReturnType: None
    AlwaysBreakBeforeMultilineStrings: false
    AlwaysBreakTemplateDeclarations: Yes
    BinPackArguments: true
    BinPackParameters: true
    BreakBeforeBraces: Custom
    BraceWrapping:
        AfterEnum: true
        AfterClass: true
        AfterControlStatement: true
        AfterFunction: true
        AfterNamespace: true
        AfterStruct: true
        AfterUnion: true
        AfterExternBlock: true
        BeforeCatch: true
        BeforeElse: true
        IndentBraces: false
        SplitEmptyFunction: false
        SplitEmptyRecord: false
        SplitEmptyNamespace: false
    BreakBeforeBinaryOperators: NonAssignment
    BreakBeforeTernaryOperators: true
    BreakConstructorInitializers: BeforeComma
    BreakInheritanceList: BeforeComma
    BreakStringLiterals: true
    ColumnLimit: 80
    CompactNamespaces: false
    ConstructorInitializerAllOnOneLineOrOnePerLine: false
    ConstructorInitializerIndentWidth: 4
    Cpp11BracedListStyle: false
    DerivePointerAlignment: false
    FixNamespaceComments: true
    ForEachMacros: ['ILIST_FOREACH', 'ILIST_FOREACH_ENTRY']
    IncludeBlocks: Regroup
    IncludeCategories:
        - Regex: '<.*>'
          Priority: 1
        - Regex: '.*'
          Priority: 2
    IndentCaseLabels: false
    IndentPPDirectives: AfterHash
    IndentWidth: 4
    IndentWrappedFunctionNames: false
    KeepEmptyLinesAtTheStartOfBlocks: false
    Language: Cpp
    NamespaceIndentation: All
    PointerAlignment: Right
    ReflowComments: true
    SortIncludes: true
    SortUsingDeclarations: false
    SpaceAfterCStyleCast: false
    SpaceAfterTemplateKeyword: true
    SpaceBeforeAssignmentOperators: true
    SpaceBeforeCpp11BracedList: false
    SpaceBeforeCtorInitializerColon: true
    SpaceBeforeParens: ControlStatements
    SpaceBeforeRangeBasedForLoopColon: true
    SpaceInEmptyParentheses: false
    SpacesBeforeTrailingComments: 1
    SpacesInAngles: false
    SpacesInCStyleCastParentheses: false
    SpacesInContainerLiterals: false
    SpacesInParentheses: false
    SpacesInSquareBrackets: false
    TabWidth: 4
    UseTab: Never
  '';
}
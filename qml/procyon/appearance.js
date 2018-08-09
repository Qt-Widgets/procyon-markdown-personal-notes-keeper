.pragma library

function baseColor() {
    return "Gainsboro";
}

function editorColor() {
    return "White";
}

function selectionColor() {
    return "SteelBlue";
}

function textColor() {
    return "Black";
}

function textColorSelected() {
    return "White";
}

function textColorModest() {
    return "Gray";
}

function fontSizeDefaultUI() {
    return 10
}

function fontSizeSmallUI() {
    return 8
}

function memoTypeIcon(typeStr) {
    switch (typeStr) {
    case "text/rich": return "icon/memo_plain_text"
    case "text/code/bash": return "icon/folder_opened"
    case "text/code/python": return "icon/folder_closed"
    }
    return "icon/memo_plain_text"
}

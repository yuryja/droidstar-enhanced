import sys

def replace_in_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    # Make memory buttons square and rounded
    content = content.replace('width: 60; height: 32', 'width: 40; height: 40')
    content = content.replace('radius: 6', 'radius: 8')
    content = content.replace('text: "Mem " + (index + 1)', 'text: "M" + (index + 1)')

    with open(filepath, 'w') as f:
        f.write(content)

replace_in_file('ui/desktop/MainTabDesktop.qml')
replace_in_file('ui/mobile/MainTab.qml')

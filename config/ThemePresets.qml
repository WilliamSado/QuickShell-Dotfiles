import QtQuick

QtObject {
    readonly property var presets: [
        {
            name: "Tela Cyan",
            dark: {
                pill: "#19383a", section: "#10282b", active: "#2d6669", popup: "#0f2022", border: "#2f6f73",
                text: "#efffff", muted: "#8fb5b8", accent: "#9cf7f2", accent2: "#77deda",
                bluetooth: "#b7fffb", clock: "#d7fffd", cpu: "#6dd3cf", memory: "#c5fffb", window: "#aef2ee"
            },
            light: {
                pill: "#d6f2f0", section: "#edfafa", active: "#a6ddd9", popup: "#f6fffe", border: "#9ad6d3",
                text: "#173638", muted: "#607f82", accent: "#178f8b", accent2: "#2aa8a3",
                bluetooth: "#0f8c98", clock: "#215f62", cpu: "#0c7e7a", memory: "#4a6f22", window: "#1a7773"
            }
        },
        {
            name: "Sakura",
            dark: {
                pill: "#3a2631", section: "#261721", active: "#73415c", popup: "#21151d", border: "#7e4965",
                text: "#fff7fb", muted: "#c49aaa", accent: "#ffb3d1", accent2: "#ff8fbd",
                bluetooth: "#ffc8df", clock: "#ffe2ee", cpu: "#ff7aaa", memory: "#ffd0e2", window: "#ffbfd9"
            },
            light: {
                pill: "#f7dce8", section: "#fff1f6", active: "#f1b8ce", popup: "#fff8fb", border: "#e59bb8",
                text: "#442333", muted: "#8d6172", accent: "#c03f76", accent2: "#d45c91",
                bluetooth: "#ac3f84", clock: "#7d3b58", cpu: "#c9346a", memory: "#8a6840", window: "#b14674"
            }
        },
        {
            name: "Mint",
            dark: {
                pill: "#24372e", section: "#16251d", active: "#47745d", popup: "#132018", border: "#4d8065",
                text: "#f5fff9", muted: "#a5c4b1", accent: "#a8f7c6", accent2: "#7edfa9",
                bluetooth: "#c7ffd9", clock: "#defee8", cpu: "#68c990", memory: "#d6ffe3", window: "#bdf2cf"
            },
            light: {
                pill: "#dff4e6", section: "#f2fbf5", active: "#bce6cb", popup: "#f8fffa", border: "#9bd6b0",
                text: "#213a2b", muted: "#657d6c", accent: "#268a4d", accent2: "#3aa468",
                bluetooth: "#217e5e", clock: "#3b6648", cpu: "#1d8144", memory: "#5d7432", window: "#2e7f4a"
            }
        },
        {
            name: "Amber",
            dark: {
                pill: "#3c3121", section: "#271f15", active: "#7a6030", popup: "#221a11", border: "#856936",
                text: "#fffaf0", muted: "#ccb48b", accent: "#ffd27d", accent2: "#ffbd5e",
                bluetooth: "#ffe0a8", clock: "#fff0c2", cpu: "#e8a94b", memory: "#ffe8a3", window: "#ffe8ad"
            },
            light: {
                pill: "#f6ead2", section: "#fff8eb", active: "#edd49f", popup: "#fffdf6", border: "#dfbd76",
                text: "#46351b", muted: "#8a7350", accent: "#a96f12", accent2: "#c2811d",
                bluetooth: "#987020", clock: "#765923", cpu: "#ad6811", memory: "#7a6b21", window: "#9a7428"
            }
        },
        {
            name: "Nord",
            dark: {
                pill: "#243246", section: "#141d29", active: "#4a617e", popup: "#111821", border: "#536f90",
                text: "#eceff4", muted: "#9aa7bd", accent: "#88c0d0", accent2: "#6faac2",
                bluetooth: "#a6d7e8", clock: "#d8f0f7", cpu: "#5f9bb6", memory: "#c4e9f2", window: "#9fd2e2"
            },
            light: {
                pill: "#dbe7f2", section: "#f1f6fb", active: "#b9d0e2", popup: "#f8fbff", border: "#9bb9d0",
                text: "#233142", muted: "#647487", accent: "#2e7084", accent2: "#3f87a0",
                bluetooth: "#2f7898", clock: "#486977", cpu: "#2f7698", memory: "#527484", window: "#3f7f97"
            }
        },
        {
            name: "Grape",
            dark: {
                pill: "#302543", section: "#20172d", active: "#644d8e", popup: "#1b1426", border: "#7156a0",
                text: "#faf5ff", muted: "#b7a0ce", accent: "#c9a7ff", accent2: "#aa86ee",
                bluetooth: "#dfc8ff", clock: "#ddd0ff", cpu: "#9469d7", memory: "#eadcff", window: "#d6b8ff"
            },
            light: {
                pill: "#eadff7", section: "#f8f2ff", active: "#d3bcec", popup: "#fcf8ff", border: "#bda1dd",
                text: "#352449", muted: "#756087", accent: "#7343ad", accent2: "#8759c8",
                bluetooth: "#7f4fb4", clock: "#665184", cpu: "#764bb6", memory: "#7b6796", window: "#7e58b0"
            }
        },
        {
            name: "Blue",
            dark: {
                pill: "#22344b", section: "#151f2d", active: "#42679a", popup: "#111a25", border: "#4b75ad",
                text: "#f4f9ff", muted: "#9eb2c9", accent: "#8ecbff", accent2: "#67b6f2",
                bluetooth: "#b9dcff", clock: "#d8efff", cpu: "#559fe0", memory: "#c9e7ff", window: "#b7dcff"
            },
            light: {
                pill: "#dcecf9", section: "#f1f8ff", active: "#b7d6ef", popup: "#f8fcff", border: "#9fc3df",
                text: "#203449", muted: "#60758b", accent: "#286fa8", accent2: "#3b8cc9",
                bluetooth: "#2d75aa", clock: "#436b88", cpu: "#2675b7", memory: "#4f7597", window: "#357ba9"
            }
        },
        {
            name: "Purple",
            dark: {
                pill: "#352543", section: "#21152d", active: "#684b99", popup: "#1d1327", border: "#7656ad",
                text: "#fbf5ff", muted: "#bea2d2", accent: "#c59cff", accent2: "#ac82ee",
                bluetooth: "#dfc0ff", clock: "#ead8ff", cpu: "#9a6fde", memory: "#eedcff", window: "#dec0ff"
            },
            light: {
                pill: "#eee0f7", section: "#faf2ff", active: "#d8bdef", popup: "#fdf8ff", border: "#c19fdf",
                text: "#3a254b", muted: "#7b638b", accent: "#7d43b5", accent2: "#955ccb",
                bluetooth: "#894eb6", clock: "#70568b", cpu: "#8350bb", memory: "#806a95", window: "#8d5bb8"
            }
        },
        {
            name: "Green",
            dark: {
                pill: "#243a29", section: "#16261a", active: "#477954", popup: "#132116", border: "#4d855b",
                text: "#f4fff7", muted: "#a4c8ad", accent: "#9cf2b6", accent2: "#72d99a",
                bluetooth: "#c4ffd6", clock: "#d7ffe2", cpu: "#5fc581", memory: "#d8ffe4", window: "#c8f7b7"
            },
            light: {
                pill: "#def3e3", section: "#f2fbf4", active: "#b9e4c4", popup: "#f8fffa", border: "#98d3a6",
                text: "#213b28", muted: "#647e69", accent: "#248844", accent2: "#39a261",
                bluetooth: "#217d58", clock: "#3b6644", cpu: "#1d803e", memory: "#5d7430", window: "#3c7f39"
            }
        }
    ]
}

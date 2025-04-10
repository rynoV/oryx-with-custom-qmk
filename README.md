# Oryx with custom QMK

This repository allows combining the convenience of [Oryx’s](https://www.zsa.io/oryx) graphical layout editing with the power of [QMK](https://qmk.fm), allowing you to customize your Oryx layout with advanced QMK features like Achordion and Repeat Key, while automating firmware builds through GitHub Actions.

For a detailed guide, check out the full [blog post here](https://blog.zsa.io/oryx-custom-qmk-features).

## How it works

Each time you run the GitHub Action, the workflow will:

1. Fetch the latest changes made in Oryx.
2. Merge them with any QMK features you've added in the source code.
3. Build the firmware, incorporating modifications from both Oryx and your custom source code.

## How to use

1. Fork this repository (be sure to **uncheck the "Copy the main branch only" option**).
2. To initialize the repository with your layout:
   - Go to the **Actions** tab.
   - Select **Fetch and build layout**.
   - Click **Run workflow**.
   - Input your layout ID and keyboard type (your layout must be public in Oryx), then run the workflow.
   - (To avoid having to input values each time, you can modify the default values at the top of the `.github/workflows/fetch-and-build-layout.yml` file).
3. A folder containing your layout will be generated at the root of the repository.
4. You can now add your custom QMK features to this folder:
   - Edit `config.h`, `keymap.c` and `rules.mk` according to the [QMK documentation](https://github.com/qmk/qmk_firmware/tree/master/docs/features).
   - Commit and push to the **main** branch.
5. You can continue editing your layout through Oryx:
   - Make your changes in Oryx.
   - Optionally, add a description of your changes in the **Some notes about what you changed** field; if provided, this will be used as commit message.
   - Confirm changes by clicking the **Compile this layout** button.
6. To build the firmware (including both Oryx and code modifications), rerun the GitHub Action. The firmware will be available for download in the action’s artifacts.
7. Flash your downloaded firmware using [Keymapp](https://www.zsa.io/flash#flash-keymap).
8. Enjoy!

## Oryx Chrome extension

To make building even easier, [@nivekmai](https://github.com/nivekmai) created an [Oryx Chrome extension](https://chromewebstore.google.com/detail/oryx-extension/bocjciklgnhkejkdfilcikhjfbmbcjal) to be able to trigger the GitHub Actions from inside Oryx itself.

## Layout tour

I've tried to focus on things that I haven't seen mentioned much, some personal experiences, and avoided going into detail on things with lots of info online already.

Highlights of this tour:

- Custom qmk integration
- Cases of hand/arm/shoulder pain and how I fixed them
- Usage notes across Linux, Windows, and MacOS
- Vim workflow tricks

### Tab keys

In the top corners I have four keys which can be tapped for switching to the previous "tab" of something. I only like to look at one thing at a time, so I often need to switch back and forth between two windows, or files in vim, or tabs in vim, or tabs in my terminal.

#### Alternate buffer

Switches to the previous vim buffer. Also useful for other applications which use vim bindings.

#### Ctrl-tab

Mostly used in my terminal to swap to the previous tab.

#### Alt-tab

For swapping to the previous operating system window (usually when referencing something in the browser).

#### Vim-tab

For swapping between vim's tabs.

I like to use neovim's built-in terminal because it lets me treat the terminal like any other buffer, however this has the downside of requiring me to exit insert/terminal mode before I can swap out of the terminal. This macro uses vim's built-in binding to go to normal mode from any other mode (so it works in terminal mode, unlike escape, see `:help *CTRL-\\_CTRL-N*`), then swaps the tab. This is nice because it works in non-terminal buffers as well.

The one downside of this mapping was with the default 100ms delay between macro steps, it could feel slow, but thankfully ZSA just made that delay configurable!

I use a 10ms delay and the keypresses are recognized on Windows, Mac, and Linux using Windows Terminal and Kitty. However this delay was too fast when I was using an alternate double escape key macro to exit terminal mode in neovim.

### Misc

#### Vim escape

This is just the first part of the vim-tab macro, see that key for some notes.

#### Escape combo

For my escape key I've mainly been using a combo on j and w, using my middle fingers.

I find it pretty comfortable, but I'm still deciding between using this combo or a dedicated escape key.

#### Caps-lock for MacOS

MacOS has their own key called the "globe" key which is used for maximizing a window. After searching about for a while including looking at qmk customizations, most solutions looked pretty finicky and the best solution I found was to remap the caps-lock key to the globe key in the system settings of macos.

#### One-shot mods

For infrequent mods, one-shot is very nice.

### Home-row mods, chordal hold, permissive hold

I switched to home row mods recently and really like it.

I don't think the setup would have been usable to me without chordal hold.

Chordal hold did cause some of my other layer key usage to break, so I added a customization to [disable chordal hold for the thumbs](https://github.com/rynoV/oryx-with-custom-qmk/blob/e6dfd2e5653b66fc97271e07f59fe7a21d55e42b/r9eJl/keymap.c#L34C1-L41C5).

TODO: permissive hold, other settings?

#### Number pad home row mod

I like this particularly in combination with relative line numbers in vim, to quickly type the number of the line I want to move to.

### Thumb usage and pain

I've had two instances of bodily pain since getting my voyager and using it daily for about 4 months now.

Both instances were due to my usage of my thumbs.

#### Layout shifted up a row

> [!NOTE]
> TLDR: I placed a frequently used key combination in way that aggravated my shoulder when I developed a habit of placing my hand to hit that combination. If you start to get pain in one side, pay attention to any differenc in resting position of your hands.

When I first got the voyager I shifted everything up one row so that it would be more like the planck (so the home row was the second row from the top).

This gave a kind-of third thumb key in the inner bottom corner of each side of the board.

This was fine and I might have kept with it, except:

Soon I started to get pain and stiffness in my left shoulder. Eventually I started trying to figure out what was happening, and one time when working I noticed my left hand was resting on the board in a different position than my right, and I discovered that I was resting aligned with my mappings for alt-tab, with the left "third-thumb key" as alt and tab in the top left corner of the left board. For my left hand to hit this combination I had to rotate my hand strangely, and when I removed this combination the pain in my left shoulder went away.

On another note, when I shifted everything back down I also noticed my hands were in a more comfortable position on the home row with thumbs on the big keys; the resting position with everything shifted up was a bit stretched out.

#### Same-hand thumb layer combinations

The second instance of pain came from using the right thumb key as a layer switch to access the arrow keys, also on the right hand. In this case the pain was in my right thumb and wrist, and has mostly gone away after recently removing the bindings for keys on other layers whose layer key is on the same hand.

> [!NOTE]
> I say "mostly" because I only made this change recently and the pain has gone away but there is still some discomfort, so I'm not sure yet if this was really the full story.

### Home-row mods on other layers

This idea is from [this great article](https://precondition.github.io/home-row-mods).

In-brief, this allows you to hit the modifiers and layer keys in any order.

This is another benefit enabled by avoiding same-hand thumb layer combinations (although the pain thing was definitely the main factor for me!)

### Universal copy-paste-cut

These key combinations work well in windows and linux, and with karabiner on mac they can work as well.

On windows they seem to work everywhere. On linux I think there might be a few places they don't work but not many. A nice benefit is they clear up ctrl-c,v,x in the terminal, and they work in emacs as well (maybe with a custom binding), so I can use the same combination pretty much everywhere.

### Qmk customization

I use [this awesome tool](https://github.com/poulainpi/oryx-with-custom-qmk) to merge oryx changes with qmk source customizations. I converted the github action into a bash script on my fork for faster build times on systems that support it (linux and mac), [you can find it here](https://github.com/rynoV/oryx-with-custom-qmk/blob/main/build.sh).

#### Macos swap cmd and ctrl

QMK has a built-in feature that allows swapping the command and control keys, which can be useful for linux/windows users trying to use macos. Currently this needs to be done in the qmk source of your layout.

I'm still trying to figure out my macos workflow, and I don't actually use this currently. I've found that with mostly working in the terminal or emacs or qutebrowser the bindings are mostly the same for these apps on macos and I don't need to swap command and control.

### Conclusion

Don't ignore bodily pain! You may be able to fix it with changes to your layout. Also I've heard it can get really bad if left unaddressed.

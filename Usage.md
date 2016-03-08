# Usage #

Fid.Gen is flexible enough to create fiducials in various sizes and levels of complexity so that the design of the markers can be tailored to your specific application requirements. For example, some of the authors own projects required more than 2000 unique symbols, but Fid.Gen can also be interesting if you only need a much smaller amount, but don't want to or can't use the default markers (e.g. due to space requirements or desire for a more custom look)

Even though Fid.Gen markers are 100% compatible with reacTIVision and are based on the design rules and approach described in [this paper](http://reactable.iua.upf.edu/pdfs/reactivision_3rditeration2005.pdf) published by the reacTIVision authors, the layout algorithm used is distinct from the original solution and is using a physics based network of springs to create the marker layout. In contrast to that, the original set of markers was designed using a genetic algorithm to optimize space requirements. Fid.Gen does not (yet) take care of such automatically, but due to its many parameters can be configured to fit many such design constraints.

## Prerequisites ##

Fid.Gen should be relatively easy to use, but if you're serious about creating a new set of markers you're advised to at least read the above mentioned [paper](http://reactable.iua.upf.edu/pdfs/reactivision_3rditeration2005.pdf) in order to understand the basic functioning and properties of the markers.

## Configuration file ##

```
# fid.gen application properties
# settings in this file will overwrite the hardcoded defaults

# window size & that of exported fiducial images
# fiducials will always be centred in this area
screen.width=1024
screen.height=1024

# fonts to use for UI and fiducial ID
ui.font.info=Georgia-14.vlw
ui.font.fiducial=Typ1451Bold-24.vlw

# render scale (you might need to adjust this when changing screen/image size)
ui.render.scale=1.4
# leaf nodes in the fiducial tree can be scaled separately from other nodes
# for better decoding rates (test different combinations)
ui.render.leaf.scale=1.41

# number of nodes all fiducials will consist of
nodes.count=22
# each fiducial must have at least 2 black leaves in order to work out
# marker orientation
nodes.black.mincount=4
nodes.black.maxcount=8
# internal model scale, final display size is interdependent on ui.render.scale
nodes.scale=180
nodes.radius=13
# base diameter of a fiducial tree node
nodes.diameter=15

# maximum number of nodes in a cluster
nodes.cluster.maxcount=10
# forced distance between clusters
nodes.cluster.distfactor=5.25
# spring strength between clusters
nodes.cluster.strength=0.05

# number of attempts to create a unique fiducial before giving up
# (meaning the set of possible combinations has been exhausted and no further
# markers can be created with the current configuration)
generator.iterations.max=100
# In order to get stable orientation readings during encoding the length of
# the marker's orientation vector needs to be maximized. Fid.Gen can automatically
# discard markers which do not have a long enough vector
# Note: the length is a percentage of the total marker size and will have to be
# much smaller if the number of nodes is reduced
generator.orientation.minlength=0.75
# purely for display purposes, number of digits the fiducial ID will be formatted to
generator.label.numdigits=4

# older versions reacTIVision did not seem to be able to decode fiducials with a longer depth sequence
# than 28 digits, Fid.Gen will discard markers which exceed this length automatically
# if you're using v1.4 or newer you can set this value to 999
tree.sequence.maxlength=28
```

## User interface ##

Fid.Gen is using Sojamo's [ControlP5](http://www.sojamo.de/libraries/controlP5/) library to create a minimal GUI, but (if pre-configured) can also be fully operated via keyboard.

The shortcuts are as follows (case insensitive):
  * **A** - accept and save current fiducial
  * **X** - reject and discard current fiducial (see next section below for why this is needed)
  * **S** - accept current fiducial and save all tree definitions generated so far (**Don't forget that important step!**)
  * **N** - discard current marker and start new session (tree defs are NOT saved automatically)
  * **L** - toggle fiducial ID display
  * **H** - toggle tree depth sequence / stats display
  * **I** - invert marker (note: you'll have to decide at the beginning of a session which way you want as this is not (yet) individual to markers)

## Watch out ##

### Generation issues ###
Even though every generated fiducial will be **UNIQUE** (always just within the current session, fiducials do not have global identity by design, but are always "local" to the set they belong to), _not every single one of them will actually be **VALID**_!!!

**The generation process definitely involves human supervision and judgement.**

There're occasions when one or more of the following things happen and in this case the marker needs to be discarded:

  * black (if on white background, else white) nodes  - the individual dots in the top part of the marker - sometimes are ending up too close to each other. The minimum distance should be the size of a dot.
  * the marker outline interrupted due to overlapping nodes
  * the marker grows to a size bigger than the window

It's not a problem to discard markers like that (or even if just don't like the look of them!) - generation of a new one only takes a second or so...

### reacTIVision issues ###
Whilst working on some projects using several hundreds of markers I've noticed that older versions of reacTIVision (pre 1.4) had issues with more complex markers whose tree depth sequence exceeds 28 characters. Fid.Gen can automatically discard these (see config settting above), but based on experience there still seems to be a 1-3% chance that a generated marker would not be successfully decoded if part of a bigger set.

This issue seems to have been fixed by Martin Kaltenbrunner with reacTIVision v1.4 and hence can be ignored.

The moral of this is story still is though:
**DO TEST ALL YOUR MARKERS BEFORE USING THEM IN A LIVE PROJECT**

## The tree index file ##

Please do not forget to **save the tree file** once you have generated all markers required. When generating hundreds of markers, consider saving regularly and then once at the end.

**Without the tree definitions the generated markers are useless to reacTIVision.**

## Last but not least: How to use the markers ##

For reacTIVision 1.3 you could specify a custom tree file via the commandline like:

```
./reactivion -t myfiducials.trees
```

In reacTIVision 1.4 you'll need to edit the supplied `reactivision.xml` file (for OSX users: this file is packaged inside the reactivision app folder, right-click on it and choose "show package contents") and add the following XML node:

```
<?xml version="1.0" encoding="ISO-8859-1" ?>
<reactivision>
...
    <fiducial engine="amoeba" tree="myfiducials.trees" />
</reactivision>
```
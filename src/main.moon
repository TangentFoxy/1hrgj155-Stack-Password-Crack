math.randomseed os.time!
import graphics from love
import random, min, floor from math

Node = require "Node"

local stack, w, h, password, first, debug, won, time, auto
stackHeight = 21

font = graphics.newFont "font/VeraMono.ttf", 20
charWidth, charHeight = font\getWidth(" "), font\getHeight!
graphics.setFont font

string.random = (len) ->
  -- inspired by github.com/rxi/lume's uuid function
  fn = ->
    -- this version -> too many possible values
    -- r = random(26*2+10+10+20+3) - 1
    -- return "1234567890!@#$%^&*()abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ-=_+[]{}\\|;:'\"/.,<>?`~ "\sub r, r
    r = random(26*2) - 1
    return "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"\sub r, r
  return "x"\rep(len)\gsub "x", fn

class TrackedNode extends Node
  @notify: (node) =>
    first = node

  new: (opts={}) =>
    super opts
    @@notify(@) unless first -- requires outside knowledge, should not be handled by the class constructor anyhow

  insert: (node) =>
    @@notify node unless @previous
    super node

  remove: =>
    @@notify(@next) unless @previous
    super!

  update: (dt) =>
    @next\update dt if @next

  draw: =>
    @next\draw! if @next

class PasswordNode extends TrackedNode
  new: (opts={}) =>
    super opts

    @string = opts.string
    @matched = {}
    for x = 1, #@string
      @matched[x] = false
    @color = opts.color or {
      unmatched: {1, 1/3, 1/3, 1}
      matched: {0.25, 1, 0.25, 1}
    }

    -- these values are based on it previously taking the last space on the stack
    @x, @y = 0, (stackHeight - 1) * charHeight
    @charX, @charY = 1, stackHeight

  update: (dt) =>
    -- TODO check if space above us has string w matching pieces of our string
    if stack[1][@charY - 1]
      -- FIND IT
      -- for now, gonna be lazy because I know password is last in the stack
      --                                        (and all StackNodes start at 1)
      checking = @previous
      while checking
        if (not checking.dropping) and checking.charY == @charY - 1 -- if right above us (and done falling)
          break
        else
          checking = checking.previous

      if checking -- if we've found one
        for x = 1, #checking.string
          if checking.string\sub(x, x) == @string\sub x, x
            @matched[x] = true

    for value in *@matched
      return unless value
    won = true -- :D

    super dt

  draw: =>
    for x = 1, #@string
      graphics.setColor(@matched[x] and @color.matched or @color.unmatched)
      graphics.rectangle "line", (x - 1) * charWidth, @y, charWidth, charHeight
      if @matched[x]
        graphics.print @string\sub(x, x), (x - 1) * charWidth, @y

    if debug
      graphics.setColor 1, 1, 1, 1
      graphics.print @string, @x, @y

    super!

class StackNode extends TrackedNode
  new: (opts={}) =>
    super opts

    @string = opts.string
    @color = opts.color or {0.8, 0.8, 1, 1}

    -- TODO fix that we are assuming we are at x == 1
    @x, @y = 0, 0
    @charX, @charY = 1, 1

    -- TODO fix that we are assuming we are at x == 1
    for x = 1, #@string
      -- print x, #@string, stack, stack[x] -- it was generating StackNodes longer than the stack...
      stack[x][@charY] = true -- take our place

  remove: =>
    -- AGHHH
    for x = @charX, @charX + #@string - 1
      stack[x][@charY] = false -- we aren't here anymore!

    super!

  update: (dt) =>
    if @dropping
      goal = @charY * charHeight
      @y = min goal, @y + dt * 100
      if @y >= goal
        @dropping = false
        for x = @charX, @charX + #@string - 1
          stack[x][@charY] = false -- clear old position
          -- stack[x][@charY + 1] = true -- claim new (already done!)
        @charY += 1

    drop = true
    for x = @charX, @charX + #@string - 1
      drop and= not stack[x][@charY + 1]
    if drop
      @dropping = true
      for x = @charX, @charX + #@string - 1
        stack[x][@charY + 1] = true -- claim new space before dropping into it

    super dt

  draw: =>
    graphics.setColor(@color)
    graphics.rectangle "line", @x, @y, #@string * charWidth, charHeight
    graphics.print @string, @x, @y

    super!

love.load = ->
  w = 3 + random 3
  h = stackHeight -- const level count for stack (last level is 'password' field)

  stack = {}
  for x = 1, w
    stack[x] = {}
    for y = 1, h - 1
      stack[x][y] = false -- stack just stores bool 'taken' spots
    stack[x][h] = true -- last row is 'taken' by nothing

  password = PasswordNode string: string.random w

time = 0
love.update = (dt) ->
  if won
    nil
  else
    time += dt
    if auto and floor(time) % 2 == 1
      love.keypressed "down"
    first\update dt if first

love.draw = ->
  first\draw! if first

  graphics.setColor 1, 1, 1, 1
  graphics.print "Crack da password!\nPress down arrow to pull more\nrandom memory onto the stack.", graphics.getWidth!/2, 0
  graphics.print "Or turn on automatic mode with A", graphics.getWidth!/2, 150
  graphics.print "Score: #{1000000 - time}", graphics.getWidth!/2, 200

  if won
    nil
    -- TODO draw end screen!

love.keypressed = (key) ->
  if key == "escape"
    love.event.quit!
  if key == "a"
    auto = not auto
  if key == "d"
    debug = not debug
  if key == "s" -- leaving in for testing
    -- len = 1 + floor random! * w
    len = max w + 2, random! * 100
    for x = 1, len
      return false if stack[x][1]
    first\insert StackNode string: string.random len
  if key == "down"
    checking = first
    while checking
      -- print checking.charY, stackHeight
      if (not checking.dropping) and checking.charY == stackHeight - 1
        break
      else
        checking = checking.next

    -- print "done checking"
    if checking -- if there's something to remove
      checking\remove!

    -- copy-pasted from above, sue me
    len = floor random! * w
    for x = 1, len
      return false if stack[x][1]
    first\insert StackNode string: string.random len

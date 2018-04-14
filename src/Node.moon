class Node
  new: (opts={}) =>
    @previous = opts.previous
    @next = opts.next

  insert: (node) =>
    if @previous
      @previous.next = node
      node.previous = @previous
    node.next = @
    @previous = node

  remove: =>
    if @previous
      @previous.next = @next
    if @next
      @next.previous = @previous

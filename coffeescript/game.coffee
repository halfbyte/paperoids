class Player
  constructor: (@game) ->
    @x = 400
    @y = 300
    @s_x = 0
    @s_y = 0
    # @angle = 0
    @rotation = 0
    @stroke = '#080'
    @strokeInvincible = "#800"
    @speed = 0;
    @lives = 3  
    @invincibility()
    @shootTimeout = false
    @moto = false
    
  invincibility: ->
    @invincible = true
    setTimeout(@dieable, 2000)
  dieable: =>
    @invincible = false
  
  left: ->
    @rotation -= 0.1
  right: ->
    @rotation += 0.1
    
  accelerate: ->
    diff_x = Math.sin(@rotation) * 0.2
    diff_y = Math.cos(@rotation) * 0.2
    speed = Math.sqrt(Math.pow(@s_x + diff_x, 2) + Math.pow(@s_y - diff_y, 2))
    unless speed > 5
      @s_x += diff_x
      @s_y -= diff_y
    @motorOn()
  brake: ->
    # @speed -= 0.1
    # @speed = -4 if (@speed < -4)
    # @motorOn()

  motorOn: =>
    unless @motor
      Wafex.start('wroom')
      @motor = true
  motorOff: =>
    if @motor
      Wafex.stop('wroom')
      @motor = false

  enableFire: =>
    @shootTimeout = false
  fire: =>
    return if @shootTimeout
    diff_x = Math.sin(@rotation) * 2
    diff_y = Math.cos(@rotation) * 2
    @game.addBullet(new Bullet(@game, @x, @y, @s_x + diff_x, @s_y - diff_y, @rotation))
    Wafex.play('pew')
    @shootTimeout = true
    setTimeout @enableFire, 200
  
  move: ->
    @x += @s_x
    @y += @s_y
    @x = 0 if @x >= 800 
    @y = 0 if @y >= 600
    @x = 800 if @x < 0 
    @y = 600 if @y < 0
    
  draw: (ctx)->
    ctx.strokeStyle = if @invincible then @strokeInvincible else @stroke
    ctx.save()
    ctx.translate(@x, @y)
    ctx.rotate(@rotation)
    ctx.beginPath()
    ctx.moveTo(0, -10)
    ctx.lineTo(7, 10)
    ctx.lineTo(-7, 10)
    ctx.closePath()
    ctx.stroke()    
    ctx.restore()

  checkCollisions: (boulders) =>
    return if @invincible
    for boulder in boulders
      
      distance = Math.abs(Math.sqrt(Math.pow(boulder.x - @x, 2) + Math.pow(boulder.y - @y, 2)))
      if distance <= boulder.size
        @lives--
        Wafex.play('boom');
        if @lives == 0
          @game.died()
        @invincibility()

class Bullet
  constructor: (@game, @x, @y, @s_x, @s_y, @angle) ->
    @stroke = '#000'
    @distance = 1000
  move: =>
    @distance -= Math.abs(Math.sqrt(Math.pow(@s_x, 2) + Math.pow(@s_y, 2)))
    if @distance < 0
      @game.removeBullet(this)
    @x += @s_x
    @y += @s_y
    @x = 0 if @x >= 800 
    @y = 0 if @y >= 600
    @x = 800 if @x < 0 
    @y = 600 if @y < 0
    @rotation += 0.03
  
  draw: (ctx) =>
    ctx.strokeStyle = @stroke
    ctx.save()
    ctx.translate(@x, @y)
    ctx.rotate(@angle)
    ctx.beginPath()
    ctx.moveTo(0,0)
    ctx.lineTo(0,10)
    ctx.stroke()
    ctx.restore()
    
  checkCollisions: (boulders) ->
    for boulder in boulders      
      distance = Math.abs(Math.sqrt(Math.pow(boulder.x - @x, 2) + Math.pow(boulder.y - @y, 2)))
      if distance <= boulder.size
        boulder.explode()
        @game.removeBullet(this)

class Boulder
  constructor: (@game, @x,@y, @size, @angle, @speed) ->
    @stroke = '#008'
    @rotation = 0
  move: ->
    @x += -@speed * Math.sin(-@angle)
    @y += -@speed * Math.cos(-@angle)
    @x = 0 if @x >= 800 
    @y = 0 if @y >= 600
    @x = 800 if @x < 0 
    @y = 600 if @y < 0
    @rotation += 0.03

  draw: (ctx)->
    ctx.strokeStyle = @stroke
    ctx.save()
    ctx.translate(@x, @y)
    ctx.rotate(@rotation)
    ctx.beginPath()
    ctx.moveTo(0, @size)
    @count = 9
    for i in [0..@count]
      x = Math.sin(2 * Math.PI / @count * i) * @size
      y = Math.cos(2 * Math.PI / @count * i) * @size
      ctx.lineTo(x, y)
    ctx.stroke()
    ctx.restore()

  explode: =>
    Wafex.play('boom')
    console.log("EXPLODE", @size)  
    if @size > 10
      @game.addBoulder(new Boulder(@game, @x, @y, @size / 2, @angle - (Math.PI / 4), @speed * 1.2))
      @game.addBoulder(new Boulder(@game, @x, @y, @size / 2, @angle + (Math.PI / 4), @speed * 1.2))
    @game.removeBoulder(this);

class window.Game
  constructor: (@canvas) ->
    
    @KEYS = {32: 'space', 38: 'up', 40: 'down', 37: 'left', 39: 'right'}
    @keysPressed = []
    Wafex.init()
    
    @$canvas = $(@canvas)
    @ctx = @$canvas.get(0).getContext('2d')
    @ctx.lineWidth = 3
    @ctx.lineJoin = 'round'
    @ctx.lineCap = 'round'
    @player = new Player(this)
    @boulders = [
      new Boulder(this, 200,200,40,2,2)
      new Boulder(this, 400,200,20,6,1)
      new Boulder(this, 800,200,10,3,0.8)
    ]
    @bullets = []
    $(document).keydown(@keyDown)
    $(document).keyup(@keyUp)
    @gameloop()
  
  keyDown: (e) =>    
    if @KEYS[e.which]
      e.preventDefault();
      @keysPressed.push(@KEYS[e.which])
          
  keyUp: (e) =>
    
    if @KEYS[e.which]
      e.preventDefault();
      @keysPressed = _(@keysPressed).without(@KEYS[e.which])
  
  addBoulder: (obj) ->
    @boulders.push(obj)
    
  removeBoulder: (obj) ->
    @boulders = _.without(@boulders, obj)
  
  addBullet: (obj) ->
    @bullets.push(obj)
    
  removeBullet: (obj) ->
    @bullets = _.without(@bullets, obj)
  died: ->
    console.log('you died!')
  cls: ->
    @ctx.clearRect(0, 0, @$canvas[0].width, @$canvas[0].height)
  gameloop: () =>
    @cls()
    @player.move()
    @player.draw(@ctx)
    if _(@keysPressed).contains('left')
      @player.left()
    if _(@keysPressed).contains('right')
      @player.right()
  
    if _(@keysPressed).contains('up')
      @player.accelerate()
    else if _(@keysPressed).contains('down')      
      @player.brake()
    else
      @player.motorOff()
      
    if _(@keysPressed).contains('space')
      @player.fire()
    
    
    for entity in @boulders
      entity.move()
      entity.draw(@ctx)
    for entity in @bullets
      entity.move()
      entity.draw(@ctx)
      entity.checkCollisions(@boulders)

    @player.checkCollisions(@boulders)

    requestAnimationFrame(@gameloop)
    
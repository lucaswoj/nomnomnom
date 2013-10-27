require = (src) ->
  document.body.appendChild(document.createElement('script')).src = src

require('http://ajax.googleapis.com/ajax/libs/jquery/2.0.3/jquery.min.js')

nom = {}

nom.getLowestFraction = (x0) ->
  eps = 0.1

  integer = Math.floor(x0)
  x0 = x0 - integer

  x = x0
  a = Math.floor(x) || 0
  h1 = 1
  k1 = 0
  h = a
  k = 1

  while (x - a > eps * k * k)
    x = 1/(x-a)
    a = Math.floor(x)
    h2 = h1
    h1 = h
    k2 = k1
    k1 = k
    h = h2 + a*h1
    k = k2 + a*k1

  integer += h if k == 1

  string = ''
  string += integer + ' ' if integer != 0
  string += h + "/" + k if k > 1
  string

class nom.Recipe

  @createFromNode: (node) ->
    $node = $ node
    new nom.Recipe
      name: $node.find("[itemprop=name]").text()
      ingredients: $.map(
        $node.find("[itemprop=ingredients]"),
        (el) -> nom.Ingredient.createFromNode(el)
      )
      steps: $.grep(
        $.map(
          $("[itemProp=recipeInstructions]").text().split('\n'),
          (step) -> new nom.Step($.trim(step))
        )
        (step) -> step.step != ""
      )
      servings: parseInt($('[itemProp=recipeYield]').text())
    
  constructor: (options) ->
    {@name, @ingredients, @steps, @servings} = options

  setServings: (servings) ->
    ratio = servings / @servings
    for ingredient in @ingredients
      ingredient.amount *= ratio
    @servings = servings

class nom.Step
  constructor: (@step) -> @done = false

class nom.Ingredient

  @UnitSystem = {Imperial: 'imperial', Metric: 'metric'}
  @UnitType = {Volume: 'volume', Mass: 'mass'}

  @units =
    tablespoon:
      aliases: ['tbsp', 'tbs']
      type: Ingredient.UnitType.Volume
      system: Ingredient.UnitSystem.Imperial
      conversion: 67.628
    teaspoon:
      aliases: ['tsp']
      type: Ingredient.UnitType.Volume
      system: Ingredient.UnitSystem.Imperial
      conversion: 202.884
    cup:
      aliases: ['cup']
      type: Ingredient.UnitType.Volume
      system: Ingredient.UnitSystem.Imperial
      conversion: 4.22675
    quart:
      aliases: ['qt']
      type: Ingredient.UnitType.Volume
      system: Ingredient.UnitSystem.Imperial
      conversion: 1.05669
    litre:
      aliases: ['liter', 'L']
      type: Ingredient.UnitType.Volume
      system: Ingredient.UnitSystem.Metric
      conversion: 1
    pound:
      aliases: ['lb']
      type: Ingredient.UnitType.Weight
      system: Ingredient.UnitSystem.Imperial
      conversion: 2.20462
    ounce:
      aliases: ['oz']
      type: Ingredient.UnitType.Weight
      system: Ingredient.UnitSystem.Imperial
      conversion: 35.274

  @createFromNode: (node) -> @createFromString($(node).text())

  @createFromString: (string) ->

    match = string.match(/([0-9]+ )?(([0-9]+)\/([0-9]+) )?\s*(.+)/)

    amount =
      (parseFloat(match[1], 10) || 0) +
      (parseInt(match[3], 10) || 0) /
      (parseInt(match[4], 10) || 1)

    unit
    for unitName, unit of @units
      unit.name = unitName

      unitNames = [unitName].concat(unit.aliases)
      # todo real pluralization
      unitNames = $.map(unitNames, (name) -> name + 's').concat(unitNames)

      for unitName in unitNames
        if (match[5].indexOf(unitName) == 0)
          name = $.trim(match[5].slice(unitName.length))
          return new nom.Ingredient(unit, amount, name)

    return new nom.Ingredient(null, amount, match[5])

  constructor: (@unit, @amount, @name) -> @done = false

  toFormattedString: () ->
    string = '<dt>' + nom.getLowestFraction(@amount)
    string += " " + @unit.name + 's</strong>' if @unit
    string += '</dt><dd>'
    string += " " + @name + "</dd>"
      

class nom.View

  constructor: (attributes) ->
    node = document.createElement(@nodeTag || 'div')
    @$node = $ node
    $.extend(@, attributes)
    @render()

class nom.IngredientsView extends nom.View
  nodeTag: 'dl'

  render: ->
    @$node.addClass("dl-horizontal")

    $.each @ingredients, (n, ingredient) =>

      $ingredientNode = $ ingredient.toFormattedString()
      @$node.append($ingredientNode)
      $ingredientNode.css cursor: 'pointer'

      $ingredientNode.one "click", =>
        ingredient.done = !ingredient.done
        @$node.empty()
        @render()

      if (ingredient.done)
        $ingredientNode.wrapInner('<strike>')

class nom.ServingsView extends nom.View

  render: ->
    @$node.text("#{@recipe.servings} Servings")
    @$node.css
      textAlign: 'center'
      fontWeight: 'bold'
      fontSize: 16
      cursor: 'pointer'

    @$node.one 'mousedown', (event) =>
      if (event.which == 1)
        @recipe.setServings(@recipe.servings + 1)
      else
        @recipe.setServings(@recipe.servings - 1)
      event.preventDefault()
      nom.modalView.render()

    @$node.one 'contextmenu', (event) -> event.preventDefault()

class nom.StepsView extends nom.View
  render: ->

    for step in @steps
      stepView = new nom.StepView(step: step)
      @$node.append(stepView.$node)

class nom.StepView extends nom.View
  render: ->
    @$node.text(@step.step)

    @$node.css
      margin: '10px 0'
      cursor: 'pointer'

    @$node.one "click", =>
      @step.done = !@step.done
      @$node.empty()
      @render()

    @$node.wrapInner('<strike>') if (@step.done)

class nom.RecipeView extends nom.View

  render: ->
    @ingredientsView = new nom.IngredientsView(ingredients: @recipe.ingredients)
    @servingsView = new nom.ServingsView(recipe: @recipe)
    @stepsView = new nom.StepsView(steps: @recipe.steps)

    @$node = $ '<div>',
      class: 'container'
      css:
        margin: '25px 45px'
      html: "<h2 style='text-align: center'><strong>#{@recipe.name}</strong></h2>"
    
    @$node.append(@servingsView.$node)
    @$node.append('<hr>')
    @$node.append(@ingredientsView.$node)
    @$node.append('<hr>')
    @$node.append(@stepsView.$node)

class nom.ModalView

  constructor: ->
    @$node = $ '<div>',
      css:
        width: 0
        height: 0
        position: 'fixed'
        top: 20
        left: '50%'
      appendTo: $('body')

    @$iframe = $ '<iframe>',
      css:
        width: 850
        height: 600
        right: -760/2
        top: 0
        backgroundColor: '#fff'
        position: 'absolute'
        boxShadow: '0 0 50px #000'
      appendTo: @$node
    
    @$iframe.contents().find('head').append $ '<link>',
      rel: 'stylesheet'
      type: 'text/css'
      href: 'http://netdna.bootstrapcdn.com/bootstrap/3.0.0/css/bootstrap.min.css'

    @recipe = nom.Recipe.createFromNode($('[itemtype="http://schema.org/Recipe"]'))

    @render()

  render: ->
    @$iframe.contents().find('body').empty()
    @recipeView = new nom.RecipeView(recipe: @recipe)
    @$iframe.contents().find('body').append @recipeView.$node

nom.modalView = new nom.ModalView()
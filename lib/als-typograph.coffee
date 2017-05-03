{CompositeDisposable} = require 'atom'
typograph = require './typograph'
{name} = require '../package'


entityTypeMap =
    'HTML': 1
    'XML': 2
    'Mixed': 4
    'No entities': 3

module.exports = AlsTypograph =
    subscriptions: null

    config:
        entity:
            title: 'Entity type'
            description: 'Type of special symbol codes. Example: `&nbsp;` for HTML, `&#160;` for XML or ready Unicode symbol for *No entities*.'
            type: 'string'
            enum: Object.keys entityTypeMap
            default: 'HTML'

        use_br:
            title: 'Put line breaks'
            description: 'Add `<br>` tags on line breaks'
            type: 'boolean'
            default: false

        use_p:
            title: 'Mark out paragraphs (`<p>`)'
            description: 'Add `<p>` tags around selected text'
            type: 'boolean'
            default: false

    activate: ->
        @subscriptions = new CompositeDisposable

        @subscriptions.add atom.commands.add 'atom-workspace',
            'als-typograph:typograph': => @typograph()

    deactivate: ->
        @subscriptions.dispose()

    typograph: ->
        if editor = atom.workspace.getActiveTextEditor()
            curText = editor.getSelectedText()

            if curText.length > 0
                config = atom.config.get name

                params = text: curText

                if config.entity
                    params.entity = entityTypeMap[config.entity]

                if config.use_br
                    params.use_br = config.use_br

                if config.use_p
                    params.use_p = config.use_p

                if config.max_nobr
                    params.max_nobr = config.max_nobr

                typograph params
                .then (result)->
                    editor.insertText result, select: true

                .catch (err)->
                    atom.notifications.addError "Can't typograph text. Some error detected",
                        detail: err

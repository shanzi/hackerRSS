publicController = {}

# home page '/'
publicController.index = (req, res) ->
    hostname = req.host
    atom_url = "#{req.host}/atom"
    res.render 'public/index', {'atom_url': atom_url}

publicController.atom = (req, res) ->
    res.type "application/atom+xml"

    
module.exports = publicController

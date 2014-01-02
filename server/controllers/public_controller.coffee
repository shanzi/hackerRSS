publicController = {}

# home page '/'
publicController.index = (req, res) ->
  if req.session.authRedirectUrl
    # just got authorized while trying to go to another route, redirect and clear that session value
    res.redirect req.session.authRedirectUrl
    req.session.authRedirectUrl = null
  else
    res.render 'public/index'
    
publicController.about = (req, res) ->    
  res.render 'public/about'    

module.exports = publicController

input = document.getElementById "atom_url"
input.onclick = (e)->
    this.focus()
    this.select()
    e.preventDefault()

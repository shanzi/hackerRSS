input = document.getElementById "rss_url"
input.onclick = (e)->
    this.focus()
    this.select()
    e.preventDefault()

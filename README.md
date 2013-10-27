### About

Nomnomnom is a bookmarklet to make online recipes more usable. It helps you remember what steps you've completed, adjust yield, convert units and more!

![nomnomnom screenshot](http://i.imgur.com/jmvGzd1.png)

This script should works for any recipe that supports the schema.org semantic recipe markup, for example this recipe for [African sweet potato and peanut stew](http://www.therecipedepository.com/recipe/650/african-sweet-potato-and-peanut-stew)

Future features may include

 - This is vaporware
 - Toggling between imperial and SI units
 - Showing a timer whenever a step mentions a time duration
 - Adjusting ingredient quantities
 - Saving recipes locally
 - Sharing recipes
 - Finding ingredient substitutions
 - Building a shopping list

### Installation

Simply drag this link to your bookmarks bar: [nomnomnom](javascript:(function(\){document.body.appendChild(document.createElement('script'\)\).src='http://raw.github.com/lucaswoj/nomnomnom/master/dist/nomnomnom.js';}\)(\);).

### Build Instructions

If you have CoffeeScript installed as a global npm package, all you need to do is run
```
coffee --watch --output dist nomnomnom.coffee --map
```

Testing the bookmarklet off your local development copy requires running a static http server. I recommend the `http-server` npm package run with caching disabled as
```
http-server . -c-1
```
If you run your http server on the project root and port `8080`, you can use this development bookmarklet: [nomnomnom dev](javascript:(function(\){document.body.appendChild(document.createElement('script'\)\).src='http://localhost:8080/dist/nomnomnom.js';}\)(\);)

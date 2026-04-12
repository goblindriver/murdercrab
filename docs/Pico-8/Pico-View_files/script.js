
function codeFontChange(){
    var code = document.querySelector('code');
    console.log("changing font from = "+code.style.fontFamily);
    if (code.style.fontFamily == "pico8" || code.style.fontFamily == "pico8_full" ||code.style.fontFamily == "Press Start 2P" || code.style.fontFamily == "" ) {
        var el = document.querySelectorAll('code');
        for(var i=0;i<el.length;i++){
            el[i].style.fontFamily = 'monospace';
            el[i].style.fontSize = '20px';
        }
    }
    else {
        var el = document.querySelectorAll('code');
        for(var i=0;i<el.length;i++){
            el[i].style.fontFamily = 'pico8';
            el[i].style.fontSize = '16px';
        }

        el = document.querySelectorAll('pre > code');
        for(var i=0;i<el.length;i++){
            el[i].style.fontFamily = 'pico8_full';
            el[i].style.fontSize = '16px';
        }
    }
}

//----------------------back to top button---------------//
function scrollFunction() {
    if (document.body.scrollTop > 1000 || document.documentElement.scrollTop > 1000) {
        backtotop.style.display = "block";
    } else {
        backtotop.style.display = "none";
    }
}

// When the user clicks on the button, scroll to the top of the document
function scrollToTop() {
    document.body.scrollTop = 0; // For Safari
    document.documentElement.scrollTop = 0; // For Chrome, Firefox, IE and Opera
}

//--------------------------side bar toggle---------------//
function toggleSideBar(){
    $("#wrapper").toggleClass("toggled");
}

//--------------------------canvas table to image---------------//
function convertToImage() {
    html2canvas(document.getElementById("tableToImage")).then( function (canvas){
        var resultDiv = document.getElementById("result");
        console.log("rendered image from table");
        var img = canvas.toDataURL("image/png");
        //need to get form data and pass with img to handler page
    } );
}


// FOR PICO-8 CODE HIGHLIGHTING
Rainbow.extend('lua', [
    {
        name: 'preset',
        pattern: /(cls|spr|sspr|line|circ|rect|rrect|oval|ovalfill|circfill|rectfill|rrectfill|fillp|print|add|del|btn|btnp|all|flr|ceil|rnd|cos|sin|atan2|mid|min|max|sqrt|sgn|abs|cursor|camera|clip|color|pget|pset|sget|sset|pal|palt|map|fset|fget|mset|mget|repeat|until|while|foreach|music|sfx|flp|ipairs|pairs|cstore|memcpy|memset|peek|poke|reload|bnot|bor|bxor|shl|shr|srand|cartdata|dget|dset|cocreate|coresume|costatus|yield|setmetatable|getmetatable|type|sub|tonum|tostr|time|menuitem|extcmd|assert|printh|stat|stop|trace|split|unpack|ord|chr)+(?=\(|\")/g
    },
    {
        name: 'string',
        pattern: /"(.*?)"/g
    },
    {
        name: 'string',
        pattern: /false|true/g
    }
]);


//FOR TINYMCE EDITOR SAVE PAGE CONTENTS TO DATABASE
function savePageContents (editor) {
    // APPEND DATA
    var data = new FormData();
    data.append('content_text', editor.getContent());

    // AJAX
    var xhr = new XMLHttpRequest();
    xhr.open('POST', "3b-save.php", true);
    xhr.onload = function(){
        if (xhr.status==200) {
            var response = JSON.parse(this.response);
            alert(response.message);
        } else { alert("ERROR LOADING 3b-save.php!"); }
    };
    xhr.send(data);
}


// SPRITE LIBRARY DISPLAY ART DETAILS
function showClipArt(src, title, code, size, creator_id, creator_name, creator_title){
    //pixel art image stuff
    document.getElementById('artDisplayBox').style.display = 'block';
    document.getElementById("artDisplayBox").classList.add('d-flex');
    document.getElementById("clipArtFull").src = src;
    document.getElementById("clipArtTitle").innerHTML = title;

    //code stuff
    //var showCode = code.replace(/-/g,"\n"); //replace all dashes with new lines to display correctly
    //document.getElementById("showPicoCode").innerHTML = showCode;

    var codeStart = "[gfx]";
    if (size=="8x8") { codeStart += "0808";  } //hexidecmal
    if (size=="16x16") { codeStart += "1010";  } //hexidecmal
    if (size=="32x32") { codeStart += "2020";  } //hexidecimal

    var copyCode = codeStart + code.replace(/-/g,""); //remove all dashes to copy correctly
    document.getElementById("copyPicoCode").innerHTML = copyCode+"[/gfx]";

    //creator data stuff
    var creatorInfo = '<a class="nerdyButton" target="_blank" href="/Profile/?id='+creator_id+'">Shared by: '+creator_title+' '+creator_name+'</a>';
    document.getElementById("spriteInfo").innerHTML = creatorInfo;
}

function copyToClipboard(elementId,buttonID) {
    var aux = document.createElement("input");
    aux.setAttribute("value", document.getElementById(elementId).innerHTML);
    document.body.appendChild(aux);
    aux.select();
    document.execCommand("copy");

    //reveal notification alert with fadeout
    $("#notification").fadeIn(500).delay(3000).fadeOut(500);
    document.body.removeChild(aux);
}

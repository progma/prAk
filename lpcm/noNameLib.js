$(document).ready(function(){
    $("div[slidedata]").each(function(i, div){
        noNameLib.createSlidesBox($(div));
    });
    $("body").keydown(function(e){
        if (e.which == 37) {
            noNameLib.back();
        }
        else if (e.which == 39) {
            noNameLib.forward();
        }
    });
});

noNameLib = {
    createSlidesBox: function(theDiv) {
        var slideList = $("<div>", {
            class: "slideList"
        });
        var innerSlides = $("<div>", {
            class: "innerSlides"
        });

        var name = theDiv.attr("slidedata");
        noNameLib.slidesName = name;

        $.getJSON(name + "/desc.json", function(data){
            noNameLib.data = data;

            $.each(data["load"], function(key, val){
                $.getScript(name + "/" + val);
            });

            $.each(data["slides"], function(key, val){
                var slideIcon = $("<div>", {
                    id: "iconOf" + val["name"],
                    class: "slideIcon",
                    style: val["icon"] ?
                        "background-image: url('" + name + "/" + val["icon"] + "')" :
                        "background-image: url('icons/" + val["type"] + ".png')"
                }).appendTo(slideList);
                var slide = $("<div>", {
                    id: val["name"],
                    class: "slideNot"
                });
                slide.appendTo(innerSlides);
            });

            slideList.appendTo(theDiv);
            innerSlides.appendTo(theDiv);

            noNameLib.hideAll();
            noNameLib.show("intro");
            noNameLib.currentSlides = noNameLib.currentSlide = "intro";
        });
    },

    hideAll: function() {
        $(".slide").addClass("slideNot").removeClass("slide");
        $(".slideIconActive").removeClass("slideIconActive");
    },

    show: function(name) {
        $.each(noNameLib.data["slides"], function(key, val){
            if (val["name"] === name)
            {
                $("#" + name).addClass("slide").removeClass("slideNot");
                $("#iconOf" + name).addClass("slideIconActive");

                $("#" + name).html("");

                if (val["type"] === "html")
                {
                    $.ajax({
                        url: noNameLib.slidesName+"/"+val["source"],
                        dataType: "text"
                    }).done(function(data){
                        $("#" + name).html(data);
                    });
                }
                else if (val["type"] === "code")
                {
                    $("<textarea>", {
                        id: "textboxOf" + name,
                        style: "width: 80%; height: 200px;"
                    }).appendTo($("#" + name));
                }
            }
        });
    },

    historyStack: new Array(),

    forward: function() {
        var kam;
        $.each(noNameLib.data["slides"], function(key, val){
            if (val["name"] === noNameLib.currentSlide)
            {
                if (!val["next"])
                {
                    alert("Toto je konec kurzu.");
                    return;
                }
                kam = val["next"];
            }
        });
        noNameLib.historyStack.push(noNameLib.currentSlides);
        noNameLib.currentSlides = kam;
        noNameLib.hideAll();
        $.each(kam.split(" "), function(key, val){
            noNameLib.show(val);
            noNameLib.currentSlide = val;
        });
    },

    back: function() {
        if (noNameLib.historyStack.length === 0)
        {
            alert("Toto je začátek kurzu.");
            return;
        }
        noNameLib.currentSlides = noNameLib.historyStack.pop();
        noNameLib.hideAll();
        $.each(noNameLib.currentSlides.split(" "), function(key, val){
            noNameLib.show(val);
            noNameLib.currentSlide = val;
        });
    }
};
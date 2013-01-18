-module(test).

-export([main/1]).

main(Data) ->
    Regex = "([a-z0-9_-]+\.)+[a-z]{2,4}/.*",
    % "((https?:\/\/)?([\w\.]+)\.([a-z]{2,6}\.?)(\/[\w\.]*)*\/?)"
    case re:run(Data, Regex, [global, {capture, all, list}]) of
        {match, Captured} ->
            [[Url]] = Captured,
            io:format("~p~n", [Url]),
            Index = string:rchr(Url, $.),
            io:format("~p~n", [Index]),
            Ext = string:right(Url, string:len(Url) - Index),
            io:format("~p~n", [Ext]),
            case Ext of
                "jpg" -> wrap_html_img(Data, Url);
                "jpeg" -> wrap_html_img(Data, Url);
                "gif" -> wrap_html_img(Data, Url);
                "png" -> wrap_html_img(Data, Url);
                _ -> Data
            end;
        nomatch -> Data
    end.
    
wrap_html_img(Data, Url) ->
    io:format("~p:~p~n", [Data, Url]),
    re:replace(Data, Url, "<img src='&' />", [{return, list}]).

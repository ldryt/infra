let
  bg = "#282828";
  red = "#cc241d";
  green = "#98971a";
  yellow = "#d79921";
  blue = "#458588";
  purple = "#b16286";
  aqua = "#689d68";
  gray = "#a89984";
  darkgray = "#1d2021";
  lightgray = "#bdae93";
in
{
  bar = {
    background = bg;
    statusline = lightgray;
    focusedWorkspace = {
      border = lightgray;
      background = lightgray;
      text = bg;
    };
    inactiveWorkspace = {
      border = darkgray;
      background = darkgray;
      text = lightgray;
    };
    activeWorkspace = {
      border = darkgray;
      background = darkgray;
      text = lightgray;
    };
    urgentWorkspace = {
      border = red;
      background = red;
      text = bg;
    };
  };

  client = {
    focused = {
      border = lightgray;
      background = lightgray;
      text = bg;
      indicator = purple;
      childBorder = darkgray;
    };
    focusedInactive = {
      border = darkgray;
      background = darkgray;
      text = lightgray;
      indicator = purple;
      childBorder = darkgray;
    };
    unfocused = {
      border = darkgray;
      background = darkgray;
      text = lightgray;
      indicator = purple;
      childBorder = darkgray;
    };
    urgent = {
      border = red;
      background = red;
      text = lightgray;
      indicator = red;
      childBorder = red;
    };
  };
}

let
  bg = "#282828";
  red = "#cc241d";
  purple = "#b16286";
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

<?php
/*
 * Menu configuration for Tailscale Plugin
 */

# $menuEntries is an array of menu entries for this plugin
# text - menu entry text
# type - status/content/output/help (main menu area)
# page - PHP file to display for this menu item
# wrap - 0/1 to hide or display the FPP header, menu, and footer on this page
#        This does not apply for pages which begin with http:// or https://

$menuEntries = Array(
    Array(
        'text' => 'Tailscale VPN',
        'type' => 'status',
        'page' => 'index.php',
        'wrap' => 1
    )
);

##############################################################################
# Display the menu entries for this plugin
# 
# It is expected that two variables are already set:
# $plugin - contains the name of the current plugin directory/repoName
# $pluginName - contains a cleaned up version of the name for display
##############################################################################

foreach ($menuEntries as $menuEntry)
{
    $menuText = $menuEntry['text'];
    $menuType = $menuEntry['type'];
    $menuPage = $menuEntry['page'];
    $menuWrap = $menuEntry['wrap'];
    
    if ($menuWrap == 1)
    {
        # Standard FPP page wrapper
        echo "<li><a href='plugin.php?plugin=" . $plugin . "&page=" . $menuPage . "'>" . $menuText . "</a></li>";
    }
    else
    {
        # No wrapper (direct link)
        if (preg_match('/^https?:\/\//', $menuPage))
        {
            echo "<li><a href='" . $menuPage . "' target='_blank'>" . $menuText . "</a></li>";
        }
        else
        {
            echo "<li><a href='/plugin.php?plugin=" . $plugin . "&nopage=1&page=" . $menuPage . "'>" . $menuText . "</a></li>";
        }
    }
}
?>

<?php
// Tailscale Plugin Menu

$menuEntries = array(
    array(
        'text' => 'Tailscale VPN',
        'type' => 'status',
        'page' => 'tailscale.php',
        'wrap' => 1
    )
);

foreach ($menuEntries as $menuEntry) {
    echo "<li><a href='plugin.php?plugin=" . $plugin . "&page=" . $menuEntry['page'] . "'>" . $menuEntry['text'] . "</a></li>";
}

<?php
// Tailscale Plugin Menu
// Only execute in proper plugin context to avoid breaking FPP

if (!isset($plugin)) {
    return;
}

$menuEntries = array(
    array(
        'text' => 'Tailscale VPN',
        'type' => 'status',
        'page' => 'tailscale.php',
        'wrap' => 1
    )
);

foreach ($menuEntries as $menuEntry) {
    echo "<li><a href='plugin.php?plugin=" . htmlspecialchars($plugin) . "&page=" . htmlspecialchars($menuEntry['page']) . "'>" . htmlspecialchars($menuEntry['text']) . "</a></li>";
}

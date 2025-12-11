<?php
# Tailscale Plugin Menu Configuration

$menuEntries = Array(
    Array(
        'text' => 'Tailscale VPN',
        'type' => 'status',
        'page' => 'tailscale.php',
        'wrap' => 1
    )
);

# Display menu entries
foreach ($menuEntries as $menuEntry)
{
    echo "<li><a href='plugin.php?plugin=" . $plugin . "&page=" . $menuEntry['page'] . "'>" . $menuEntry['text'] . "</a></li>";
}
?>

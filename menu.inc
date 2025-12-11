<?php
/*
 * Menu configuration for Tailscale Plugin
 * This file adds the plugin to FPP's navigation menu
 */

// Add menu entry under Status/Control
$menu = [
    'Status/Control' => [
        'Tailscale VPN' => [
            'page' => 'plugin.php?plugin=testing-tailscale-fpp&page=index.html',
            'pluginPage' => 'index.html'
        ]
    ]
];

return $menu;
?>

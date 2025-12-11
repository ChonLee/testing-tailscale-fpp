<?php
/*
 * Tailscale Plugin API for FPP
 * Handles all backend operations for the Tailscale management interface
 */

header('Content-Type: application/json');

$PLUGIN_DIR = "/opt/fpp/plugins/fpp-tailscale";
$CONFIG_FILE = "$PLUGIN_DIR/config.json";
$LOG_FILE = "/var/log/fpp-tailscale.log";

/**
 * Execute a shell command and return output
 */
function execCommand($cmd) {
    exec($cmd . " 2>&1", $output, $return_code);
    return [
        'output' => implode("\n", $output),
        'return_code' => $return_code
    ];
}

/**
 * Read configuration file
 */
function readConfig() {
    global $CONFIG_FILE;
    
    if (file_exists($CONFIG_FILE)) {
        $config = json_decode(file_get_contents($CONFIG_FILE), true);
        return $config ?: [];
    }
    
    return [
        'auto_connect' => false,
        'accept_routes' => false,
        'advertise_exit' => false,
        'hostname' => 'fpp-player'
    ];
}

/**
 * Write configuration file
 */
function writeConfig($config) {
    global $CONFIG_FILE;
    return file_put_contents($CONFIG_FILE, json_stringify($config, JSON_PRETTY_PRINT)) !== false;
}

/**
 * Get Tailscale status
 */
function getTailscaleStatus() {
    // Check if tailscaled is running
    $daemonCheck = execCommand("pgrep -x tailscaled");
    if ($daemonCheck['return_code'] !== 0) {
        return [
            'connected' => false,
            'status' => 'Tailscale daemon not running',
            'daemon_running' => false
        ];
    }
    
    // Get detailed status using tailscale status --json
    $result = execCommand("tailscale status --json");
    
    if ($result['return_code'] === 0) {
        $status = json_decode($result['output'], true);
        
        if ($status && isset($status['Self'])) {
            $self = $status['Self'];
            return [
                'connected' => true,
                'daemon_running' => true,
                'ip' => $self['TailscaleIPs'][0] ?? 'N/A',
                'hostname' => $self['HostName'] ?? 'N/A',
                'status' => 'Connected',
                'online' => $self['Online'] ?? false,
                'auth_url' => null
            ];
        }
    }
    
    // Check if we need authentication
    $authCheck = execCommand("tailscale status");
    if (strpos($authCheck['output'], 'run `tailscale up`') !== false || 
        strpos($authCheck['output'], 'Logged out') !== false) {
        
        // Try to get auth URL
        $authResult = execCommand("tailscale up --timeout=1s 2>&1 || true");
        $authUrl = null;
        
        // Extract URL from output
        if (preg_match('/https:\/\/login\.tailscale\.com\/[^\s]+/', $authResult['output'], $matches)) {
            $authUrl = $matches[0];
        }
        
        return [
            'connected' => false,
            'daemon_running' => true,
            'status' => 'Authentication required',
            'auth_url' => $authUrl
        ];
    }
    
    return [
        'connected' => false,
        'daemon_running' => true,
        'status' => 'Disconnected'
    ];
}

/**
 * Connect to Tailscale
 */
function connectTailscale() {
    $config = readConfig();
    
    $args = [];
    if ($config['accept_routes']) {
        $args[] = '--accept-routes';
    }
    if (!empty($config['hostname'])) {
        $args[] = '--hostname=' . escapeshellarg($config['hostname']);
    }
    
    $cmd = "tailscale up " . implode(' ', $args);
    $result = execCommand($cmd);
    
    // Check if we got an auth URL
    $authUrl = null;
    if (preg_match('/https:\/\/login\.tailscale\.com\/[^\s]+/', $result['output'], $matches)) {
        $authUrl = $matches[0];
    }
    
    return [
        'success' => $result['return_code'] === 0 || $authUrl !== null,
        'message' => $result['output'],
        'auth_url' => $authUrl
    ];
}

/**
 * Disconnect from Tailscale
 */
function disconnectTailscale() {
    $result = execCommand("tailscale down");
    return [
        'success' => $result['return_code'] === 0,
        'message' => $result['output']
    ];
}

/**
 * Get recent logs
 */
function getLogs() {
    global $LOG_FILE;
    
    if (file_exists($LOG_FILE)) {
        $lines = file($LOG_FILE);
        $recentLines = array_slice($lines, -50); // Last 50 lines
        return implode('', $recentLines);
    }
    
    return "No logs available";
}

// Main API router
$action = $_GET['action'] ?? '';

try {
    switch ($action) {
        case 'getStatus':
            $status = getTailscaleStatus();
            echo json_encode([
                'success' => true,
                'status' => $status
            ]);
            break;
            
        case 'getConfig':
            $config = readConfig();
            echo json_encode([
                'success' => true,
                'config' => $config
            ]);
            break;
            
        case 'saveConfig':
            $input = json_decode(file_get_contents('php://input'), true);
            if ($input && writeConfig($input)) {
                echo json_encode([
                    'success' => true,
                    'message' => 'Configuration saved successfully'
                ]);
            } else {
                echo json_encode([
                    'success' => false,
                    'message' => 'Failed to save configuration'
                ]);
            }
            break;
            
        case 'connect':
            $result = connectTailscale();
            echo json_encode($result);
            break;
            
        case 'disconnect':
            $result = disconnectTailscale();
            echo json_encode($result);
            break;
            
        case 'getLogs':
            $logs = getLogs();
            echo json_encode([
                'success' => true,
                'logs' => $logs
            ]);
            break;
            
        default:
            echo json_encode([
                'success' => false,
                'message' => 'Unknown action: ' . $action
            ]);
    }
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => 'Error: ' . $e->getMessage()
    ]);
}
?>

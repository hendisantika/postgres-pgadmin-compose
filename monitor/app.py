#!/usr/bin/env python3
"""Docker Health Monitoring Dashboard"""

import os
import json
import subprocess
from datetime import datetime
from flask import Flask, render_template, jsonify

app = Flask(__name__)

def run_command(cmd):
    """Run a shell command and return output"""
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=10)
        return result.stdout.strip(), result.returncode == 0
    except Exception as e:
        return str(e), False

def get_container_stats():
    """Get container statistics"""
    containers = []

    # Get container info
    cmd = "docker ps --format '{{json .}}'"
    output, success = run_command(cmd)

    if not success:
        return []

    for line in output.strip().split('\n'):
        if not line:
            continue
        try:
            container = json.loads(line)
            name = container.get('Names', '')

            # Get health status
            health_cmd = f"docker inspect --format='{{{{.State.Health.Status}}}}' {name} 2>/dev/null || echo 'none'"
            health, _ = run_command(health_cmd)

            # Get container stats
            stats_cmd = f"docker stats --no-stream --format '{{{{json .}}}}' {name}"
            stats_output, _ = run_command(stats_cmd)

            stats = {}
            if stats_output:
                try:
                    stats = json.loads(stats_output)
                except:
                    pass

            containers.append({
                'name': name,
                'image': container.get('Image', ''),
                'status': container.get('Status', ''),
                'ports': container.get('Ports', ''),
                'health': health if health else 'none',
                'cpu': stats.get('CPUPerc', '0%'),
                'memory': stats.get('MemUsage', 'N/A'),
                'memory_percent': stats.get('MemPerc', '0%'),
                'network_io': stats.get('NetIO', 'N/A'),
                'block_io': stats.get('BlockIO', 'N/A'),
            })
        except json.JSONDecodeError:
            continue

    return containers

def get_postgres_status():
    """Get PostgreSQL specific status"""
    status = {
        'connected': False,
        'version': 'N/A',
        'database_size': 'N/A',
        'active_connections': 0,
        'uptime': 'N/A'
    }

    pg_user = os.environ.get('POSTGRES_USER', 'postgres')
    pg_db = os.environ.get('POSTGRES_DB', 'postgres')

    # Test connection and get version
    cmd = f"docker exec postgres_db psql -U {pg_user} -d {pg_db} -t -c \"SELECT version();\" 2>/dev/null"
    output, success = run_command(cmd)
    if success and output:
        status['connected'] = True
        status['version'] = output.split(',')[0].replace('PostgreSQL ', '') if output else 'N/A'

    # Get database size
    cmd = f"docker exec postgres_db psql -U {pg_user} -d {pg_db} -t -c \"SELECT pg_size_pretty(pg_database_size('{pg_db}'));\" 2>/dev/null"
    output, success = run_command(cmd)
    if success and output:
        status['database_size'] = output.strip()

    # Get active connections
    cmd = f"docker exec postgres_db psql -U {pg_user} -d {pg_db} -t -c \"SELECT count(*) FROM pg_stat_activity;\" 2>/dev/null"
    output, success = run_command(cmd)
    if success and output:
        try:
            status['active_connections'] = int(output.strip())
        except:
            pass

    # Get uptime
    cmd = f"docker exec postgres_db psql -U {pg_user} -d {pg_db} -t -c \"SELECT date_trunc('second', current_timestamp - pg_postmaster_start_time());\" 2>/dev/null"
    output, success = run_command(cmd)
    if success and output:
        status['uptime'] = output.strip()

    return status

def get_table_stats():
    """Get table statistics from app schema"""
    tables = []
    pg_user = os.environ.get('POSTGRES_USER', 'postgres')
    pg_db = os.environ.get('POSTGRES_DB', 'postgres')

    cmd = f"""docker exec postgres_db psql -U {pg_user} -d {pg_db} -t -c "
        SELECT json_agg(row_to_json(t)) FROM (
            SELECT
                schemaname || '.' || relname as table_name,
                n_live_tup as row_count,
                pg_size_pretty(pg_total_relation_size(schemaname || '.' || relname)) as size
            FROM pg_stat_user_tables
            WHERE schemaname = 'app'
            ORDER BY n_live_tup DESC
        ) t;
    " 2>/dev/null"""

    output, success = run_command(cmd)
    if success and output and output.strip() != '':
        try:
            tables = json.loads(output.strip()) or []
        except:
            pass

    return tables

@app.route('/')
def dashboard():
    """Render the dashboard"""
    return render_template('dashboard.html')

@app.route('/api/status')
def api_status():
    """API endpoint for status data"""
    return jsonify({
        'timestamp': datetime.now().isoformat(),
        'containers': get_container_stats(),
        'postgres': get_postgres_status(),
        'tables': get_table_stats()
    })

@app.route('/api/health')
def api_health():
    """Simple health check endpoint"""
    return jsonify({'status': 'ok'})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080, debug=False)

# The Insight query could be more precise
resource "aws_cloudwatch_dashboard" "app" {
  dashboard_name = "${var.service_name}-${var.environment}"
  dashboard_body = <<EOF
  {
    "widgets": [
        {
            "type": "log",
            "x": 0,
            "y": 0,
            "width": 24,
            "height": 6,
            "properties": {
                "query": "SOURCE '${aws_cloudwatch_log_group.nginx.name}' | filter @message like /HTTP/ | stats count(*) as pageHits by bin(1m)",
                "region": "${var.region}",
                "stacked": true,
                "view": "timeSeries",
                "title": "${var.service_name}-${var.environment}-page-hits"
            }
        }
    ]
}
EOF
}
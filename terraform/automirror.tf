// The following implements AutoMirror functionality https://github.com/3CORESec/AWS-AutoMirror
// Thanks Tiago Faria (@0xtf) and 3CORESec for your awesome contribution to the community!

resource "null_resource" "mirror_session_del_wait" {
  depends_on = [
                 aws_ec2_traffic_mirror_target.security_onion_sniffing,
                 aws_ec2_traffic_mirror_filter.so_mirror_filter
               ]
  provisioner "local-exec" {
    when    = destroy
    command = <<-EOD
echo "Waiting for mirror sessions to be destroyed..."; sleep 60s;
EOD
  }
}

// The following implements AutoMirror functionality https://github.com/3CORESec/AWS-AutoMirror

resource "aws_iam_role_policy" "auto_mirror_policy" {
  depends_on = [ aws_ec2_traffic_mirror_target.security_onion_sniffing ]
  count = var.auto_mirror ? 1 : 0
  name = "auto_mirror_policy"
  role = aws_iam_role.auto_mirror_role[count.index].id

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:*"
            ],
            "Resource": "arn:aws:logs:*:*:*"
        },
        {
            "Sid": "AutoMirrorExecutionPolicy",
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeInstances",
                "ec2:DescribeTrafficMirrorFilters",
                "ec2:DescribeTrafficMirrorTargets",
                "ec2:CreateTags",
                "ec2:CreateTrafficMirrorSession",
                "ec2:DescribeTrafficMirrorSessions",
                "ec2:createTrafficMirrorFilterRule",
                "ec2:createTrafficMirrorFilter"
            ],
            "Resource": "*"
        }
    ]
  }
  EOF
}

resource "aws_iam_role" "auto_mirror_role" {
  count         = var.auto_mirror ? 1 : 0
  name = "auto_mirror_role"

  assume_role_policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "lambda.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  }
  EOF
}

data "archive_file" "zip" {
  count         = var.auto_mirror ? 1 : 0
  type        = "zip"
  source_file = "./AutoMirror/auto_mirror_lambda.js"
  output_path = "./AutoMirror/auto_mirror_lambda.zip"
}

resource "aws_lambda_function" "auto_mirror_lambda" {
  depends_on = [
    aws_ec2_traffic_mirror_target.security_onion_sniffing
  ]
  count         = var.auto_mirror ? 1 : 0
  filename      = "${data.archive_file.zip[count.index].output_path}"
  function_name = "auto_mirror_lambda"
  role          = "${aws_iam_role.auto_mirror_role[count.index].arn}"
  handler       = "auto_mirror_lambda.handler"
  source_code_hash = "${data.archive_file.zip[count.index].output_base64sha256}"
  runtime          = "nodejs12.x"
  timeout = 30
}

resource "aws_cloudwatch_event_rule" "auto_mirror_rule" {
  depends_on = [
    aws_ec2_traffic_mirror_target.security_onion_sniffing
  ]
  count         = var.auto_mirror ? 1 : 0
  name        = "auto_mirror_rule"
  description = "Configure mirror"

  event_pattern = <<PATTERN
{
  "source": [
    "aws.ec2"
  ],
  "detail-type": [
    "EC2 Instance State-change Notification"
  ],
  "detail": {
    "state": [
      "pending"
    ]
  }
}
PATTERN
}

resource "aws_cloudwatch_event_target" "auto_mirror_lambda" {
  depends_on = [
    aws_ec2_traffic_mirror_target.security_onion_sniffing
  ]
  count         = var.auto_mirror ? 1 : 0
  rule      = "${aws_cloudwatch_event_rule.auto_mirror_rule[count.index].name}"
  target_id = "auto_mirror_lambda"
  arn       = "${aws_lambda_function.auto_mirror_lambda[count.index].arn}"
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  depends_on = [
    aws_ec2_traffic_mirror_target.security_onion_sniffing
  ]
  count         = var.auto_mirror ? 1 : 0
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.auto_mirror_lambda[count.index].function_name}"
  principal     = "events.amazonaws.com"
  source_arn     = "${aws_cloudwatch_event_rule.auto_mirror_rule[count.index].arn}"
}

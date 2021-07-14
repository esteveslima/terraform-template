output "sqs_url" {
    description = "sqs queue url"
    value = aws_sqs_queue.fifo_queue.url
}
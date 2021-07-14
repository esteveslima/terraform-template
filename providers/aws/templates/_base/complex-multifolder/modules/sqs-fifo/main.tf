resource "aws_sqs_queue" "fifo_queue" {
  name                        = "${var.name}-queue.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
}

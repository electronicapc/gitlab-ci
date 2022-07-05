terraform {
  backend "http" {
  }
  required_version = "~> 1.2.4"
  required_providers {
    random   = "~> 2.1"
    template = "~> 2.1"
    local    = "~> 1.2"
  }
}
variable "words" {
  default = {
    nouns      = ["army", "panther", "walnuts", "sandwich", "Zeus", "banana", "cat", "jellyfish", "jigsaw", "violin", "milk", "sun"]
    adjectives = ["bitter", "sticky", "thundering", "abundant", "chubby", "grumpy"]
    verbs      = ["run", "dance", "love", "respect", "kicked", "baked"]
    adverbs    = ["delicately", "beautifully", "quickly", "truthfully", "wearily"]
    numbers    = [42, 27, 101, 73, -5, 0]
  }
  description = "A word pool to use for Mad Libs"
  type        = map(list(string))
}
locals {
  uppercase_words = { for k, v in var.words : k => [for s in v : upper(s)] if k != "numbers"
  }
}

variable "num_files" { #A
  default = 5
  type    = number
} #A}

resource "random_shuffle" "random_nouns" {
  count = var.num_files
  input = local.uppercase_words["nouns"] #B
}
resource "random_shuffle" "random_adjectives" {
  count = var.num_files
  input = local.uppercase_words["adjectives"]
} #B }

resource "random_shuffle" "random_verbs" {
  count = var.num_files
  input = local.uppercase_words["verbs"] #B
}

resource "random_shuffle" "random_adverbs" {
  count = var.num_files
  input = local.uppercase_words["adverbs"]
} #B }

resource "random_shuffle" "random_numbers" {
  count = var.num_files
  input = var.words["numbers"] #C

}
#data "template_file" "madlib" {       #A
#  template = file("./caixainput.txt") #B
#  vars = {                            #C
#    ADJECTIVE0 = random_shuffle.random_adjectives.result[0]
#    ADJECTIVE1 = random_shuffle.random_adjectives.result[1]
#    ADJECTIVE2 = random_shuffle.random_adjectives.result[2]
#    ADJECTIVE3 = random_shuffle.random_adjectives.result[3]
#    ADJECTIVE4 = random_shuffle.random_adjectives.result[4]
#    NOUN0      = random_shuffle.random_nouns.result[0]
#    NOUN1      = random_shuffle.random_nouns.result[1]
#    NOUN2      = random_shuffle.random_nouns.result[2]
#    NOUN3      = random_shuffle.random_nouns.result[3]
#    NOUN4      = random_shuffle.random_nouns.result[4]
#    NOUN5      = random_shuffle.random_nouns.result[5]
#    NOUN6      = random_shuffle.random_nouns.result[6]
#    NOUN7      = random_shuffle.random_nouns.result[7]
#    NOUN8      = random_shuffle.random_nouns.result[8]
#    NOUN9      = random_shuffle.random_nouns.result[9]
#    NUMBER0    = random_shuffle.random_numbers.result[0]
#    VERB0      = random_shuffle.random_verbs.result[0]
#    VERB1      = random_shuffle.random_verbs.result[1]
#  }
#}



#resource "local_file" "mad_lib" {
#  content  = data.template_file.madlib.rendered
#  filename = "outGCP_Control.txt"
#}

resource "local_file" "mad_lib" {
  count = var.num_files
  content = templatefile("random.txt",
    {
      nouns      = random_shuffle.random_nouns[count.index].result
      adjectives = random_shuffle.random_adjectives[count.index].result
      verbs      = random_shuffle.random_verbs[count.index].result
      adverbs    = random_shuffle.random_adverbs[count.index].result
      numbers    = random_shuffle.random_numbers[count.index].result

  })
  filename = "madlibs/madlib-${count.index}.txt"
}

variable "templates" { #A
  default = ["templates/alice.txt", "templates/observatory.txt", "templates/photographer.txt"]
  type    = list(string)
}

resource "local_file" "mad_libeach" {
  count = var.num_files
  content = templatefile(element(var.templates, count.index), #B
    { nouns      = random_shuffle.random_nouns[count.index].result
      adjectives = random_shuffle.random_adjectives[count.index].result
      verbs      = random_shuffle.random_verbs[count.index].result
      adverbs    = random_shuffle.random_adverbs[count.index].result
      numbers    = random_shuffle.random_numbers[count.index].result
  })
  filename = "madlibs/madlibeach-${count.index}.txt"
}

data "archive_file" "mad_libs" {
  depends_on  = [local_file.mad_libeach]
  type        = "zip"
  output_path = "madlibs.zip" #
  source_dir  = "./madlibs"   #C
}

using Base.Test
import Base.insert!

abstract SuffixTrie

type SuffixTrieNode <: SuffixTrie
  value
  children::Array{SuffixTrieNode}
  index::Int64
end

SuffixTrieNode(value, children) = SuffixTrieNode(value, children, -1)
SuffixTrieNode(value) = SuffixTrieNode(value, [], -1)

type SuffixTrieRoot <: SuffixTrie
  children::Array{SuffixTrieNode}
end

SuffixTrieRoot() = SuffixTrieRoot([])

function is_leaf(node::SuffixTrieNode)
  return node.index == -1
end

function is_prefix_match(s1::String, s2::String)
  if length(s1) == length(s2)
    return s1 == s2
  elseif length(s1) < length(s2)
    return s1 == s2[1:length(s1)]
  else
    return s2 == s1[1:length(s2)]
  end
end

function find_match(nodes::Array{SuffixTrieNode}, suffix::String)
  for node in nodes
    if is_prefix_match(string(node.value), suffix)
      return node
    end
  end

  return None
end

function find_or_create_next_node(nodes::Array{SuffixTrieNode}, suffix::String)
  next = find_match(nodes, suffix)
  if next == None
    next = SuffixTrieNode(suffix[1])
    push!(nodes, next)
  end
  next
end

function insert!(suffix_trie::SuffixTrieRoot, suffix::String, index::Int)
  next = find_or_create_next_node(suffix_trie.children, suffix)
  insert!(next, suffix[2:end], index)
end

function insert!(node::SuffixTrieNode, suffix::String, index::Int)
  if isempty(suffix)
    node.index = index
  else
    next = find_or_create_next_node(node.children, suffix)
    insert!(next, suffix[2:end], index)
  end
end

function construct_suffix_trie(text::String)
  text = string(text, '$')
  suffixes = [text[i:end] for i in 1:length(text)]

  ret = SuffixTrieRoot()

  for (suffix, index) in zip(suffixes, 1:length(suffixes))
    insert!(ret, suffix, index)
  end

  ret
end

construct_suffix_trie("abc")

for node in construct_suffix_trie("panamabanana").children
  println(node)
end

##
## Tests
##

function type_tests()
  leaf = SuffixTrieNode(10, [])
  @test is_leaf(leaf) == true
end

type_tests()

function construct_suffix_trie_test()
#   @test BioTrieModule.BioTrieRoot == typeof(construct_suffix_trie("abcd123"))
end

construct_suffix_trie_test()

function is_prefix_match_test()
  @test is_prefix_match("a", "ab") == true
  @test is_prefix_match("c", "ab") == false
end

is_prefix_match_test()


# "ATAAATG\$"

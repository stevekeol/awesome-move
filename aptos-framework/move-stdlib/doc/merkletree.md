
<a name="0x1_merkletree"></a>

# Module `0x1::merkletree`

Utility for converting a Move value to its binary representation in BCS (Binary Canonical
Serialization). BCS is the binary encoding for Move resources and other non-module values
published on-chain. See https://github.com/aptos-labs/bcs#binary-canonical-serialization-bcs for more
details on BCS.
@ESChain



-  [Function `to_bytes`](#0x1_merkletree_to_bytes)
-  [Specification](#@Specification_0)


<pre><code></code></pre>



<a name="0x1_merkletree_to_bytes"></a>

## Function `to_bytes`

Return the binary representation of <code>v</code> in BCS (Binary Canonical Serialization) format


<pre><code><b>public</b> <b>fun</b> <a href="merkletree.md#0x1_merkletree_to_bytes">to_bytes</a>&lt;MoveValue&gt;(v: &MoveValue): <a href="vector.md#0x1_vector">vector</a>&lt;u8&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>native</b> <b>public</b> <b>fun</b> <a href="merkletree.md#0x1_merkletree_to_bytes">to_bytes</a>&lt;MoveValue&gt;(v: &MoveValue): <a href="vector.md#0x1_vector">vector</a>&lt;u8&gt;;
</code></pre>



</details>

<a name="@Specification_0"></a>

## Specification



Native function which is defined in the prover's prelude.


<a name="0x1_merkletree_serialize"></a>


<pre><code><b>native</b> <b>fun</b> <a href="merkletree.md#0x1_merkletree_serialize">serialize</a>&lt;MoveValue&gt;(v: &MoveValue): <a href="vector.md#0x1_vector">vector</a>&lt;u8&gt;;
</code></pre>


[move-book]: https://move-language.github.io/move/introduction.html

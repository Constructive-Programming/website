// Two phone books built by inserting entries in order (later
// numbers win), then the entries both books agree on. A Dict is-a
// Set of pairs, so one-value-per-key is re-imposed at every put.
object Before:
  type Dict[K, V] = Set[(K, V)]

  def put[K, V](d: Dict[K, V], k: K, v: V): Dict[K, V] =
    d.filterNot(_._1 == k) + ((k, v))

  def fill(es: List[(String, Int)]): Dict[String, Int] =
    es.foldLeft(Set.empty[(String, Int)]) { (d, e) =>
      put(d, e._1, e._2)
    }

  def common(xs: List[(String, Int)],
             ys: List[(String, Int)]): Set[(String, Int)] =
    fill(xs) & fill(ys)

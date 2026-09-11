// The same phone books as a Map, which owns one-value-per-key;
// entries is the arrow back into the world of sets.
object After:
  def entries[K, V](m: Map[K, V]): Set[(K, V)] =
    m.toSet // natural in V

  def fill(es: List[(String, Int)]): Map[String, Int] =
    es.foldLeft(Map.empty[String, Int])(_ + _)

  def common(xs: List[(String, Int)],
             ys: List[(String, Int)]): Set[(String, Int)] =
    entries(fill(xs)) & entries(fill(ys))

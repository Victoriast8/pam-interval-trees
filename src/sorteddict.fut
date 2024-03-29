import "dict"
import "../lib/github.com/diku-dk/sorts/merge_sort"

module sorteddict : dict = {
    type key = i32
    type~ dict 'v = [](key, v)

    -- Stolen from: https://futhark-lang.org/examples/binary-search.html
    -- TODO: analyze and do eytzinger_index
    local def binary_search [n] 't (lte: t -> t -> bool) (xs: [n]t) (x: t) : i64 =
        let (l, _) =
            loop (l, r) = (0, n-1) while l < r do
            let t = l + (r - l) / 2
            in if x `lte` xs[t]
            then (l, t)
            else (t+1, r)
        in l
    
    -- let's define a sort function that use some predefined sort
    local def sort 'v (d : dict v) : dict v =
        merge_sort_by_key (\i -> i.0) (i32.<=) d

    def map 'a 'b (f: a -> b) (d : dict a) : dict b =
        map (\(k, v) -> (k, (f v))) d

    def reduce 'a (f : a -> a -> a) (ne : a) (d : dict a) : a =
        (unzip d).1 |> reduce f ne

    -- if we sort before removing duplicates, we can remove duplicates by checking neighbors 
    def nub_sorted 'v (d : dict v) : dict v =
        if (head d).0 != (last d).0 then
            let dflg = map2 (\(x,_) (y,_) -> x == y) d (rotate (-1) d)
            in (zip dflg d |> filter (\(flg,_) -> not flg) |> unzip).1
        else take 1 d

    def many [n] 'v (ns : [n]key) (ts : [n]v) : dict v =
        map2 (\n t -> (n,t)) ns ts |> sort |> nub_sorted

    def single 'v (n : key) (t : v) : dict v =
        [(n, t)]
    
    def union 'v (d : dict v) (d' : dict v) : dict v =
        d ++ d' |> sort |> nub_sorted

    def lookup 'v (n : key) (d : dict v) : opt v =
        let bs = binary_search (<=) (unzip d).0 n
        in if length d > 0 && d[bs].0 == n then #some d[bs].1 else #none
}

-- module mk_arraydict (P:{type t val ==: t -> t -> bool}) =
--  {type key = P.t
--  }
-- module m = mk_arraydict f32
-- læs futhark bogen (specielt kapitel 4 om moduler)
-- parametricering af modul funktioner som ovenstående, kan bruges som yderligere abstraktion.
-- https://futhark-book.readthedocs.io/en/latest/modules.html
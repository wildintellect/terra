


setMethod("geomtype", signature(x="SpatVector"), 
	function(x){ 
		x@ptr$type()
	}
)
setMethod("geomtype", signature(x="SpatVectorProxy"), 
	function(x){ 
		x@ptr$v$type()
	}
)


setMethod("datatype", signature(x="SpatVector"), 
	function(x){ 
		x@ptr$df$get_datatypes()
	}
)


setMethod("is.lines", signature(x="SpatVector"), 
	function(x) {
		geomtype(x) == "lines"
	}
)

setMethod("is.polygons", signature(x="SpatVector"), 
	function(x) {
		geomtype(x) == "polygons"
	}
)
setMethod("is.points", signature(x="SpatVector"), 
	function(x) {
		grepl("points", geomtype(x))
	}
)


setMethod("geomtype", signature(x="Spatial"), 
	function(x){ 
		type <- sub("spatial", "", as.vector(tolower(class(x)[1])))
		type <- sub("dataframe", "", type)
		if (type %in% c("grid", "pixels")) type <- "raster"
		type
	}
)

setMethod("geom", signature(x="SpatVector"), 
	function(x, wkt=FALSE, hex=FALSE, df=FALSE){
		if (hex) {
			x@ptr$hex()
		} else if (wkt) {
			x@ptr$getGeometryWKT()
			# or via geos with 
			# x@ptr$wkt()
		} else {
			g <- x@ptr$get_geometry()
			g <- do.call(cbind, g)
			colnames(g) <- c("geom", "part", "x", "y", "hole")[1:ncol(g)]
			if (df) {
				data.frame(g)
			} else {
				g
			}
		}
	}
)

setMethod("crds", signature(x="SpatVector"), 
	function(x, df=FALSE){
		g <- x@ptr$coordinates()
		g <- do.call(cbind, g)
		colnames(g) <- c("x", "y")
		if (df) {
			data.frame(g)
		} else {
			g
		}
	}
)

setMethod("crds", signature(x="SpatRaster"), 
	function(x, df=FALSE, na.rm=TRUE){
		x <- as.points(x, na.rm=na.rm)
		crds(x, df=df)
	}
)


setMethod("dim", signature(x="SpatVector"), 
	function(x){ 
		c(nrow(x), ncol(x))
	}
)

setMethod("dim", signature(x="SpatVectorProxy"), 
	function(x){ 
		c(x@ptr$v$geom_count, x@ptr$v$ncol())
	}
)


as.data.frame.SpatVector <- function(x, row.names=NULL, optional=FALSE, geom=NULL, ...) {
	d <- .getSpatDF(x@ptr$df, ...)
	# fix empty names 
	colnames(d) <- x@ptr$names
	if (!is.null(geom)) {
		geom <- match.arg(toupper(geom), c("WKT", "HEX", "XY"))
		if (geom == "XY") {
			if (!grepl("points", geomtype(x))) {
				error("as.data.frame", 'geom="XY" is only valid for point geometries')
			}
			if (nrow(d) > 0) {
				d <- cbind(d, crds(x))
			} else {
				d <- data.frame(crds(x), ...)
			}
		} else {
			g <- geom(x, wkt=geom=="WKT", hex=geom=="HEX")
			if (nrow(d) > 0) {
				d$geometry <- g
			} else {
				d <- data.frame(geometry=g, stringsAsFactors=FALSE, ...)
			}
		}
	}
	d
}
setMethod("as.data.frame", signature(x="SpatVector"), as.data.frame.SpatVector)


get.data.frame <- function(x) {
	v <- vect()
	v@ptr <- x@ptr$v
	d <- as.data.frame(v)
	d[0,,drop=FALSE]
}


as.list.SpatVector <- function(x, geom=NULL, ...) {
	if (is.null(geom)) {
		x@ptr$df$values()
	} else {
		as.list(as.data.frame(x, geom=geom))
	}
}
setMethod("as.list", signature(x="SpatVector"), as.list.SpatVector)



setMethod ("expanse", "SpatVector", 
	function(x, unit="m", transform=TRUE) {
		a <- x@ptr$area(unit, transform, double());
		x <- messages(x, "expanse");
		return(abs(a))
	}
)


setMethod("perim", signature(x="SpatVector"), 
	function(x) {
		p <- x@ptr$length();
		x <- messages(x, "length");
		return(p)
	}
)

setMethod("length", signature(x="SpatVector"), 
	function(x) {
		x@ptr$size()
	}
)


setMethod("fillHoles", signature(x="SpatVector"), 
	function(x, inverse=FALSE) {
		if (inverse) {
			x@ptr <- x@ptr$get_holes()
		} else {
			x@ptr <- x@ptr$remove_holes()
		}
		messages(x)
	}
)



#setMethod("eliminate", signature(x="SpatVector"), 
#	function(x, y) {
#		x@ptr <- x@ptr$eliminate(y@ptr)
#		messages(x)
#	}
#)



setMethod("centroids", signature(x="SpatVector"), 
	function(x, inside=FALSE) {
		if (inside) {
			x@ptr <- x@ptr$point_on_surface(TRUE)
		} else {
			x@ptr <- x@ptr$centroid(TRUE)
		}
		messages(x)
	}
)




setMethod("densify", signature(x="SpatVector"), 
	function(x, interval, equalize=TRUE) {
		x@ptr <- x@ptr$densify(interval, equalize)
		messages(x)
	}
)


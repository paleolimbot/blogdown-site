---
title: 'Class-based Views and Model Formsets in Django'
author: Dewey Dunnington
date: '2018-01-20'
slug: []
categories: []
tags: ["Django", "Python", "Tutorials"]
subtitle: ''
summary: ''
authors: []
lastmod: '2018-01-20T16:37:40+00:00'
featured: no
image:
  caption: ''
  focal_point: ''
  preview_only: no
projects: []
---

<a href="https://docs.djangoproject.com/en/dev/topics/class-based-views/intro/">Generic class-based views in Django</a> are powerful and result in minimal code to handle the basic tasks of viewing, creating, and modifying models. Recently I was trying to find a way to create a bunch of models at once (in my case, lab samples that tend to get generated in batches) in an application using class-based views. Creating a single model using a class-based view is handled by the <a href="https://docs.djangoproject.com/en/dev/ref/class-based-views/generic-editing/">django.views.generic.CreateView class</a>, but creating multiple models using a Formset isn't supported using generic class-based views (as far as I can tell from a pretty lengthy search...). Fortunately, it is easy to do and requires very little code!


Using a `CreateView`, one can provide describe a view that automatically creates and validates a form based on the model specification:

```python
from django.views import generic
from django.urls import reverse_lazy
from . import models

class SampleAddView(generic.CreateView):
    model = models.Sample
    fields = ['name', 'location', 'created']
    success_url = reverse_lazy('lims:sample_list')
    template_name = 'lims/sample_form.html'
```

Using the template below, this gets rendered to the page, and will redirect to the sample list on success (providing helpful error messages if form validation fails).

```
<form action="" method="post">
    {% csrf_token %}
    {{ form }}
    <input type="submit" value="Create" />
</form>
```

To use a `Formset` instead of a `Form`, we need to make a few modifications to the code, since we are no longer dealing with a single object. Since we are still dealing with a `Form`, we can use the `FormView` generic view instead of `CreateView`. In particular, we need to instantiate the model `Formset` class using a `QuerySet`, or it will use `Model.objects.all()`, which is probably never what you want. To get around this, we can instantiate the form class using `queryset=Model.objects.none()` (along with the rest of the form keyword arguments, which are generated using the `FormView.get_form_kwargs()` method). The only other thing that needs to be handled is the actual saving of the individual objects. Because the `Formset` is a model formset, each form is a `ModelForm` with a `.save()` method. Iterating through the forms by overriding `form_valid()` in the class-based view takes care of these new model instances getting saved.


```python
from django.views import generic
from django.urls import reverse_lazy
from django.forms import modelformset_factory
from . import models


class SampleAddView(generic.FormView):
    success_url = reverse_lazy('lims:sample_list')
    form_class = modelformset_factory(
        models.Sample,
        fields=['name', 'collected', 'location'],
        extra=3
    )
    template_name = 'lims/sample_form.html'

    def get_form_kwargs(self):
        kwargs = super(SampleAddView, self).get_form_kwargs()
        kwargs["queryset"] = models.Sample.objects.none()
        return kwargs

    def form_valid(self, form):
        for sub_form in form:
            if sub_form.has_changed():
                sub_form.save()

        return super(SampleAddView, self).form_valid(form)
```

And that's it! There's far prettier ways to render the `Formset` in the template, which is already well-described in the [Django documentation on formsets](https://docs.djangoproject.com/en/dev/topics/forms/formsets/).
